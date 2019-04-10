#!/bin/bash
######################################################################
#        Name: chirographer.sh
# Description: Chirographer performs dozens of nmap script scans on 25 different port-categories (like ftp, http, ssh, SMB, etc.)
# Output: *_script_*.html
#   ASCII-ART: http://patorjk.com/software/taag/#p=display&f=ANSI%20Shadow&t=%20%20%20%20RED%20TEAM%0ACHIROGRAPHER
######################################################################VERSION="1.0"

#spinner
sp="                                                WhiteFerrari          "

BC="\e[00;30m" #black color
RC="\e[1;31m" #red color
GC="\e[1;32m" #green color
NC="\e[00m" #no color
CC="\e[1;34m" #blue color
SC="\e[1;34m" #spinner color
YC="\e[1;33m" #spinner color
OUT="output"

# trap ctrl+c and call ctrl_c()
trap ctrl_c INT

cmd[0]="ftp;21;banner,ftp-anon,ftp-bounce,ftp-proftpd-backdoor,ftp-vsftpd-backdoor; ;"
cmd[1]="http;80,8000,8080,8081,443,8443,10000;http*; ;"
cmd[2]="snmp;161;snmp*;-sU;"
cmd[3]="ssh;22;ssh*; ;"
cmd[4]="telnet;23;banner,telnet-brute; ;"
cmd[5]="smb;139,445;smb*;-sU;"
cmd[6]="smtp;25;banner,smtp-commands,smtp-open-relay,smtp-strangeport,smtp-enum-users; ;"
cmd[7]="dns;53;dns-blacklist,dns-cache-snoop,dns-nsec-enum,dns-nsid,dns-random-srcport,dns-random-txid,dns-recursion,dns-service-discovery,dns-update,dns-zeustracker,dns-zone-transfer;-sU;"
cmd[8]="dhcp;67;dhcp-discover;-sU;"
cmd[9]="nfs;111;nfs-ls,nfs-showmount,nfs-statfs,rpcinfo; ;"
cmd[10]="ntp;123;ntp-monlist;-sU;"
cmd[11]="nbstat;137,139,445;nbstat;-sU;"
cmd[12]="MS08-067;137,139,445;smb-vuln-ms08-067;-sU;"
cmd[13]="MS06-025;137,139,445;smb-vuln-ms06-025;-sU;"
cmd[14]="MS07-029;137,139,445;smb-vuln-ms07-029;-sU;"
cmd[15]="conficker;137,139,445;smb-vuln-conficker;-sU;"
cmd[16]="CVE2009-3103;137,139,445;smb-vuln-cve2009-3103;-sU;"
cmd[17]="regsvc-dos;137,139,445;smb-vuln-regsvc-dos;-sU;"
cmd[18]="SMB;137,139,445;msrpc-enum,smb-enum-domains,smb-enum-groups,smb-enum-processes,smb-enum-sessions,smb-enum-shares,smb-enum-users,smb-mbenum,smb-os-discovery,smb-security-mode,smb-server-stats,smb-system-info,smbv2-enabled,stuxnet-detect;-sU;"
cmd[19]="LDAP;389;ldap-rootdse; ;"
cmd[20]="mssql;1433,1434;ms-sql*;-sU;"
cmd[21]="MySQL;3306;mysql-databases,mysql-empty-password,mysql-info,mysql-users,mysql-variables; ;"
cmd[22]="RDP;3389;rdp*; ;"
cmd[23]="vnc;5900;vnc*; ;"
cmd[24]="SIP;5060;sip-enum-users,sip-methods;-sU;"

ARGUMENTS="-vvv -Pn -sS --open --stats-every 4s"

scan()
{

    for index in `seq 0 24`; do
      STATUS=""
      
      ID=$( echo ${cmd[$index]} | cut -d ";" -f1 )
      PORTS=$( echo ${cmd[$index]} | cut -d ";" -f2 )
      SCRIPTS=$( echo ${cmd[$index]} | cut -d ";" -f3 )
      FLAGS=$( echo ${cmd[$index]} | cut -d ";" -f4 )
            
      if [ -z "$1" ]; then #no argument was passed, process all
        echo -e "${GC}[+]${NC} ${ID} script scan started."
        echo -e "${GC}[+]${NC} nmap -e $INT -vvv ${ARGUMENTS} ${FLAGS} -p ${PORTS} -iL .CHIR --script ${SCRIPTS} -oA ${PROJECT}_script_${ID}"
        echo -e "${GC}[+]${NC} NSE Scripts: $SCRIPTS"
        nmap -e $INT ${ARGUMENTS} ${FLAGS} -p ${PORTS} -iL .CHIR --script ${SCRIPTS} -oA ../${PROJECT}_script_${ID} &>/dev/null &
        
        sleep 5
        until [ "$STATUS" = "success" ]; do
            PERCENT=`cat "${PROJECT}_script_${ID}.xml" 2>/dev/null |grep "percent" |cut -d '"' -f 6 |tail -1 |cut -d "." -f 1`
            STATUS=`cat "${PROJECT}_script_${ID}.xml" 2>/dev/null |grep -i "exit" |cut -d '"' -f 10`

            progressbar && spin

            # do work
            sleep 0.2
        done

        endspin

        /usr/bin/xsltproc ${PROJECT}_script_${ID}.xml -o ../${PROJECT}_script_${ID}.html
        echo -e "${GC}[+]${NC} HTML report generated: ${PROJECT}/${PROJECT}_script_${ID}.html"
      else
        if [ $ID == "$1" ]; then
        
            echo -e "${GC}[+]${NC} ${ID} script scan started."
            echo -e "${GC}[+]${NC} nmap -e $INT -vvv ${ARGUMENTS} ${FLAGS} -p ${PORTS} -iL .CHIR --script ${SCRIPTS} -oA ${PROJECT}_script_${ID}"
            echo -e "${GC}[+]${NC} NSE Scripts: $SCRIPTS"
            nmap -e $INT ${ARGUMENTS} ${FLAGS} -p ${PORTS} -iL .CHIR --script ${SCRIPTS} -oA ${PROJECT}_script_${ID} &>/dev/null &            
            
            sleep 5
            until [ "$STATUS" = "success" ]; do
                PERCENT=`cat "${PROJECT}_script_${ID}.xml" 2>/dev/null |grep "percent" |cut -d '"' -f 6 |tail -1 |cut -d "." -f 1`
                STATUS=`cat "${PROJECT}_script_${ID}.xml" 2>/dev/null |grep -i "exit" |cut -d '"' -f 10`

                progressbar && spin

                # do work
                sleep 0.2
            done

            endspin

            /usr/bin/xsltproc ${PROJECT}_script_${ID}.xml -o ../${PROJECT}_script_${ID}.html
            echo -e "${GC}[+]${NC} HTML report generated: ${GC}${PROJECT}/${PROJECT}_script_${ID}.html${NC}"
        fi
      fi      
    done
}

function exit_error()
{
    echo -e "${RC}[!] ${1}...Exiting${NC}"
    echo ""
    setterm -cursor on
    
    rm "${OUT}/.excludetmp" 2>/dev/null
    rm "${OUT}/.excludeiplist" 2>/dev/null
    exit 1
}

#user pressed ctrl_c
function ctrl_c() {
        exit_error
}

title_message()
{
    clear
    echo -e "${BC}##############################################################################${NC}"    
}

progressbar ()
{
	 printf "\r${GC}[+] ${SC}%3d%% complete:  " $PERCENT
}
spin()
{
   setterm -cursor off
   printf "\b${sp:sc++:44} ${NC}"
   
   ((sc==${#sp})) && sc=0
}
endspin()
{
   printf "\r%s\n" "$@"
   setterm -cursor on
}

sc=0

title_message

# Check if root
if [[ $EUID -ne 0 ]]; then
        exit_error "This program must be run as root. Run again with 'sudo'."
fi

echo ""
if [ -n "$1" ]; then
    unset PROJECT
else
    PROJECT=$(cat .PROJECT)
fi

if [ -z $PROJECT ]; then

    echo -e "${GC}[*]${NC} Projects detected:"
               
    for i in $(\ls -d ../*/ | grep -v '^\.\./_' | grep -v '^\.\./\.'); do 
        
        echo -e "${YC}[-] ${NC}$(echo ${i} | cut -d '.' -f3 | cut -d '/' -f2)"
    done
    echo ""
    read -e -p "$(echo -e ${CC}"[?]"${NC}" Which project should be used? ")" PROJECT

    ls $PROJECT/ &>/dev/null

    if [ $? = 1 ]; then
        echo ""
        exit_error "The directory cannot be read, check the path and try again."
    fi
fi
INT=$(cat .INT 2>&1)
if [ $? = 1 ]; then
    title_message

    TMP_INT=$(ifconfig | grep "UP" |cut -d$'\n' -f1 | cut -d ":" -f1)

    echo ""
    echo -e "${GC}[*]${NC} The following network interfaces are available"
    echo ""

    for iface in $(ifconfig | grep "UP" |cut -d ":" -f1)
    do
        echo -e "${YC}[-] ${NC}${iface} [$(ifconfig ${iface} | grep 'inet ' | cut -d ' ' -f 10)]"    
    done;
        
    echo ""

    read -e -p "$(echo -e ${CC}"[?]"${NC}" Enter a network interface to scan ("${TMP_INT}"): ")" INT

    if [ -z $INT ]; then
        INT=$TMP_INT
    fi

    ifconfig | grep -i -w $INT &>/dev/null

    if [ $? = 1 ]; then	
        exit_error "The interface you entered does not exist. Check and try again."    
    fi

    echo $INT > .INT
fi

UP=$(cat ../$PROJECT/${OUT}/${PROJECT}_hosts_Up.txt 2>&1)
if [ $? = 1 ]; then
    exit_error "The file ${PROJECT}/${OUT}/${PROJECT}_hosts_Up.txt was not found.  Check the path and try again!"
fi

title_message

cd ../$PROJECT
if [ $? = 1 ]; then
    exit_error "Can't find the ${PROJECT} directory."
fi

cd $OUT
if [ $? = 1 ]; then
    exit_error "Can't find the ${PROJECT}/${OUT} directory."
fi

title_message

cat *Info.gnmap &>/dev/null
if [ $? = 1 ]; then
  exit_error "${PROJECT}/${OUT}/*Info.gnmap was not found."
fi

rm .CHIR &>/dev/null
grep ' 23/open' *Info.gnmap 2>/dev/null | cut -d " " -f 2 | sort | uniq > .CHIR
if [[ $(cat .CHIR | wc -l) -gt 0 ]]; then 
    scan "telnet"
fi

rm .CHIR &>/dev/null
grep ' 22/open' *Info.gnmap 2>/dev/null| cut -d " " -f 2 | sort | uniq > .CHIR 2>/dev/null
if [[ $(cat .CHIR | wc -l) -gt 0 ]]; then 
    scan "ssh"
fi

rm .CHIR &>/dev/null
grep ' 21/open' *Info.gnmap 2>/dev/null| cut -d " " -f 2 | sort | uniq > .CHIR 2>/dev/null
if [[ $(cat .CHIR | wc -l) -gt 0 ]]; then 
    scan "ftp"
fi

rm .CHIR &>/dev/null
sleep 1

grep ' 80/open' *Info.gnmap 2>/dev/null| cut -d " " -f 2 | sort | uniq > _TMP
grep ' 8000/open' *Info.gnmap 2>/dev/null| cut -d " " -f 2 | sort | uniq >> _TMP
grep ' 8080/open' *Info.gnmap 2>/dev/null| cut -d " " -f 2 | sort | uniq >> _TMP
grep ' 8081/open' *Info.gnmap 2>/dev/null| cut -d " " -f 2 | sort | uniq >> _TMP
grep ' 443/open' *Info.gnmap 2>/dev/null| cut -d " " -f 2 | sort | uniq >> _TMP
grep ' 8443/open' *Info.gnmap 2>/dev/null| cut -d " " -f 2 | sort | uniq >> _TMP
grep ' 10000/open' *Info.gnmap 2>/dev/null| cut -d " " -f 2 | sort | uniq >> _TMP

cat _TMP | sort | uniq > .CHIR 2>/dev/null
rm _TMP &>/dev/null

if [[ $(cat .CHIR | wc -l) -gt 0 ]]; then 
    scan "http"
fi

rm .CHIR &>/dev/null
grep ' 161/open' *Info.gnmap 2>/dev/null| cut -d " " -f 2 | sort | uniq > .CHIR 2>/dev/null
if [[ $(cat .CHIR | wc -l) -gt 0 ]]; then 
    scan "snmp"
fi

rm .CHIR &>/dev/null
grep ' 25/open' *Info.gnmap 2>/dev/null| cut -d " " -f 2 | sort | uniq > .CHIR 2>/dev/null
if [[ $(cat .CHIR | wc -l) -gt 0 ]]; then 
    scan "smtp"
fi

rm .CHIR &>/dev/null
grep ' 53/open' *Info.gnmap 2>/dev/null| cut -d " " -f 2 | sort | uniq > .CHIR 2>/dev/null
if [[ $(cat .CHIR | wc -l) -gt 0 ]]; then 
    scan "dns"
fi

rm .CHIR &>/dev/null
grep ' 67/open' *Info.gnmap 2>/dev/null| cut -d " " -f 2 | sort | uniq > .CHIR 2>/dev/null
if [[ $(cat .CHIR | wc -l) -gt 0 ]]; then 
    scan "dhcp"
fi

rm .CHIR &>/dev/null
grep ' 111/open' *Info.gnmap 2>/dev/null| cut -d " " -f 2 | sort | uniq > .CHIR 2>/dev/null
if [[ $(cat .CHIR | wc -l) -gt 0 ]]; then 
    scan "nfs"
fi

rm .CHIR &>/dev/null
grep ' 123/open' *Info.gnmap 2>/dev/null| cut -d " " -f 2 | sort | uniq > .CHIR 2>/dev/null
if [[ $(cat .CHIR | wc -l) -gt 0 ]]; then 
    scan "ntp"
fi

rm .CHIR &>/dev/null
grep ' 137/open' *Info.gnmap 2>/dev/null| cut -d " " -f 2 | sort | uniq > _TMP
grep ' 139/open' *Info.gnmap 2>/dev/null| cut -d " " -f 2 | sort | uniq >> _TMP
grep ' 445/open' *Info.gnmap 2>/dev/null| cut -d " " -f 2 | sort | uniq >> _TMP

cat _TMP | sort | uniq > .CHIR 2>/dev/null
rm _TMP

if [[ $(cat .CHIR | wc -l) -gt 0 ]]; then 
    scan "MS08-067"
    scan "MS07-029"
    scan "conficker"
    scan "CVE2009-3103"
    scan "regsvc-dos"
    scan "smb"
fi

rm .CHIR &>/dev/null
grep ' 389/open' *Info.gnmap 2>/dev/null| cut -d " " -f 2 | sort | uniq > .CHIR 2>/dev/null
if [[ $(cat .CHIR | wc -l) -gt 0 ]]; then 
    scan "LDAP"
fi

rm .CHIR &>/dev/null
grep ' 1433/open' *Info.gnmap 2>/dev/null| cut -d " " -f 2 | sort | uniq > _TMP
grep ' 1434/open' *Info.gnmap 2>/dev/null| cut -d " " -f 2 | sort | uniq >> _TMP

cat _TMP | sort | uniq > .CHIR 2>/dev/null
rm _TMP

if [[ $(cat .CHIR | wc -l) -gt 0 ]]; then 
    scan "mssql"
fi

rm .CHIR &>/dev/null
grep ' 3306/open' *Info.gnmap 2>/dev/null| cut -d " " -f 2 | sort | uniq > .CHIR 2>/dev/null
if [[ $(cat .CHIR | wc -l) -gt 0 ]]; then 
    scan "MySQL"
fi

rm .CHIR &>/dev/null
grep ' 3389/open' *Info.gnmap 2>/dev/null| cut -d " " -f 2 | sort | uniq > .CHIR 2>/dev/null
if [[ $(cat .CHIR | wc -l) -gt 0 ]]; then 
    scan "RDP"
fi

rm .CHIR &>/dev/null
grep ' 5900/open' *Info.gnmap 2>/dev/null| cut -d " " -f 2 | sort | uniq > .CHIR 2>/dev/null
if [[ $(cat .CHIR | wc -l) -gt 0 ]]; then 
    scan "vnc"
fi

rm .CHIR &>/dev/null
grep ' 5060/open' *Info.gnmap 2>/dev/null| cut -d " " -f 2 | sort | uniq > .CHIR 2>/dev/null
if [[ $(cat .CHIR | wc -l) -gt 0 ]]; then 
    scan "SIP"
fi

rm .CHIR &>/dev/null

echo -e "${GC}[+]${NC} Scans are 100% complete"
echo -e "${GC}[+]${NC} R3D 734M Chirographer is complete." 

exit 0
