#!/usr/bin/python
# -*- coding: utf-8 -*-

###################################################################################################
# Name: kicker.py
# Description: Kicker reads nmap xml output, and tries to see if any open ports are web ports.  Failed attempts print a "Kicked" message to the screen. Output is tab-delimited.
# Output: *_kicker.txt
# Ascii Art: http://patorjk.com/software/taag/#p=display&f=ANSI%20Shadow&t=RED%20TEAM%0A%20%20KICKER
###################################################################################################

import httplib
import os, sys
import re

BC="\033[00;30m" #black color
RC="\033[1;31m"  #red color
GC="\033[1;32m"  #green color
NC="\033[00m"    #no color
CC="\033[1;34m"  #blue color
SC="\033[34m"  #spinner color
YC="\033[1;33m"  #spinner color
OUT="output"   # output directory

print BC + "################################################" + NC

reg_open_ports = re.compile(r'([0-9]+/open)')
reg_ip_addr = re.compile(r'([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})')

project = open('.PROJECT', 'r').read().replace('\n', '')
    
os.chdir('../' + project + '/output')

outfile = open('../' + project + '_kicker.txt', 'w')
outfile.truncate()
outfile.write('TYPE\tIP\tPORT\tCODE\tMESSAGE\n')

files = [f for f in os.listdir('.') if os.path.isfile(f)]

for filename in files:
    if re.match(project + "_.*Info.gnmap", filename):
        with open(filename , 'r') as nmap_file:
            for line in nmap_file:
                if re.search(reg_ip_addr, line):
                    ip = re.search(reg_ip_addr, line)     
                    for m in re.finditer(reg_open_ports, line):
                        port = m.group(0).replace('/open', '').replace(' ', '')                
                        try:
                            conn = httplib.HTTPConnection(ip.group(0), port, timeout=6)
                            conn.request('HEAD', '/')
                            r1 = conn.getresponse()
                            outfile.write('HTTP\t%s\t%s\t%d\t%s\n' % (ip.group(0), port, r1.status, r1.reason))
                            print 'HTTP\t%s\t%s\t%d\t%s' % (ip.group(0), port, r1.status, r1.reason)                       
                        except Exception as ex:                   
                            try:
                                conn = httplib.HTTPSConnection(ip.group(0), port, timeout=6)
                                conn.request('HEAD', '/')
                                r1 = conn.getresponse()
                                outfile.write('HTTPS\t%s\t%s\t%d\t%s\n' % (ip.group(0), port, r1.status, r1.reason))
                                print 'HTTPS\t%s\t%s\t%d\t%s' % (ip.group(0), port, r1.status, r1.reason)
                            except Exception as ex:
                                print "Kicked\t" + ip.group(0) + "\t" + port + "\ttwice"
                                
                            conn.close()

                        conn.close()
                        outfile.flush()
                        os.fsync(outfile.fileno())
        nmap_file.close()
        
outfile.close()

print "\nR3D 734M Kicker is complete."
