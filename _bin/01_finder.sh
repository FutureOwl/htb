#!/bin/bash
######################################################################
#        Name: finder.sh
# Description: Finder sets up a new project and performs an initial scan for hosts. This script is used to create the host-list used by all other scripts.
# Output: output/*_hosts_Up.txt
#   ASCII-ART: http://patorjk.com/software/taag/#p=display&f=ANSI%20Shadow&t=RED%20TEAM%0A%20%20FINDER
######################################################################

#spinner
sp="                                                RalphyZ & lvl4lvl4530y          "

BC="\e[00;30m" #black color
RC="\e[1;31m"  #red color
GC="\e[1;32m"  #green color
NC="\e[00m"    #no color
CC="\e[1;34m"  #blue color
SC="\e[1;34m"  #spinner color
YC="\e[1;33m"  #spinner color
OUT="output"   # output directory

# trap ctrl+c and call ctrl_c()
trap ctrl_c INT

function exit_error()
{
    echo -e "${RC}[!] ${1}...Exiting${NC}"
    echo ""
    setterm -cursor on
    
    rm ".excludetmp" 2>/dev/null
    rm ".excludeiplist" 2>/dev/null
    exit 1
}

#user pressed ctrl_c
function ctrl_c() {
        exit_error
}

title_message()
{
    clear
    echo -e "${BC}################################################${NC}"    
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

if [ -n "$1" ]; then
    unset PROJECT
else
    PROJECT=$(cat .PROJECT)
fi

if [ -z $PROJECT ]; then
    title_message

    echo ""

    TMP_PROJECT="scan_$(date "+%Y%m%d_%H%M%S")"
    read -e -p "$(echo -e ${CC}"[?]"${NC}" Enter a Name for the scan ("${TMP_PROJECT}"): "${NC})" PROJECT

    if [ -z $PROJECT ]; then
        PROJECT=$TMP_PROJECT
    fi

    echo $PROJECT | grep -v '^[_.]' &>/dev/null

    if [ $? = 1 ]; then
        echo -e "${RC}[!] ${NC}Invalid filename. Cannot start with '_' or '.' Please try again."
        read -e -p "$(echo -e ${CC}"[?]"${NC}" Enter a Name for the scan ("${TMP_PROJECT}"): "${NC})" PROJECT

        if [ -z $PROJECT ]; then
            PROJECT=$TMP_PROJECT
        fi

        echo $PROJECT | grep -v '^[_.]' &>/dev/null

        if [ $? = 1 ]; then
            exit_error "${RC}DO YOU NOT UNDERSTAND ENGLISH? ¿Hablas español? Nombre de archivo inválido. No se puede empezar con ' _ ' o ' . '"
        fi   
    fi
fi
#get the IP Address and netmask
ipaddress=$(ifconfig $INT 2>/dev/null| grep "inet " | cut -d " " -f 10)
netmask=$(ifconfig $INT 2>/dev/null| grep netmask | cut -d " " -f 13)

#check to see if the IP Address and netmask are set...exit if not
if [[ -z "$ipaddress" || -z "$netmask" ]]; then
    exit_error "Unable to determine the IP Address or netmask."
fi

#Separate the octets of the IP Address
ip_A="$(echo $ipaddress | cut -d "." -f 1)"
ip_B="$(echo $ipaddress | cut -d "." -f 2)"
ip_C="$(echo $ipaddress | cut -d "." -f 3)"
ip_D="$(echo $ipaddress | cut -d "." -f 4)"

#Separate the octets of the netmask
nm_A="$(echo $netmask | cut -d "." -f 1)"
nm_B="$(echo $netmask | cut -d "." -f 2)"
nm_C="$(echo $netmask | cut -d "." -f 3)"
nm_D="$(echo $netmask | cut -d "." -f 4)"

#Calculate the Minimum IP Address with logical AND of IP and netmask octets
min_A=$(($ip_A & $nm_A))
min_B=$(($ip_B & $nm_B))
min_C=$(($ip_C & $nm_C))
min_D=$((($ip_D & $nm_D) + 1))

#Calculate the Maximum IP Address with logical OR of IP Address and 
#bitwise NOT of netmask (add 256)
max_A=$((($ip_A | ~$nm_A) + 256))
max_B=$((($ip_B | ~$nm_B) + 256))
max_C=$((($ip_C | ~$nm_C) + 256))
max_D=$((($ip_D | ~$nm_D) + 256))

#Append the octets with periods to get the minimum and maximum IP Addresses
minimum=$min_A.$min_B.$min_C.$min_D
maximum=$max_A.$max_B.$max_C.$max_D

TMP_RANGE="${minimum}-${max_D}"

title_message

echo ""
echo -e "${GC}[*]${NC} Your source IP address is set as follows:"
echo -e "${GC}[+] "$ipaddress"${NC} with the netmask of ${GC}"$netmask"${NC}"
echo -e "${GC}[*]${NC} Enter nmap-compatible target, range, or input filename${NC}"
echo ""
read -e -p "$(echo -e ${CC}"[?]"${NC}" Scan Target ("${TMP_RANGE}"): ")" RANGE

if [ -z $RANGE ]; then
    RANGE=$TMP_RANGE
fi

mkdir -p "../$PROJECT/$OUT" &>/dev/null
echo "$PROJECT" > .PROJECT
cd "../$PROJECT/$OUT"
echo $INT > .INT

title_message

echo ""
echo -e "${GC}[+]${NC} Excluding your source IP address of ${GC}"$ipaddress"${NC} from the scan.${NC}"
echo ""
read -e -p "$(echo -e ${CC}"[?]"${NC}" Exclude anything else? (y/N): ")" EXCLUDEANS

if [[ $EXCLUDEANS = yes ]] || [[ $EXCLUDEANS = y ]] || [[ $EXCLUDEANS = Y ]] || [[ $EXCLUDEANS = YES ]]; then
    echo -e '${GC}[*]${NC} Enter the IP addresses to exclude i.e 192.168.1.1, 192.168.1.1-10.'
    echo -e '${GC}[*]${NC} You can also enter the full path to an exclude file (can tab complete)'
    read -e -p "$(echo -e ${CC}"[?]"${NC}" Exclude IPs: ")" EXCLUDEDIPS
        
    if [ -n $EXCLUDEDIPS ]; then
        #check if manual input or a file
        echo $EXCLUDEDIPS |egrep '[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}.' &>/dev/null
        
        if [ $? = 0 ]; then
            echo ""
            echo -e "${GC}[*]${NC} Excluding the following additional IP addresses from the scan${NC}"
            echo ""
            echo $EXCLUDEDIPS |tee .excludeiplist
            echo "$ipaddress" >> .excludeiplist
            echo ""
        else
            echo ""
            echo -e "${GC}[*]${NC} You entered a file as the exclusion input, checking if it is readable.${NC}"
            echo ""
            
            if [ -n $EXCLUDEIPS]; then 
                cat $EXCLUDEDIPS &>/dev/null
                
                if [ $? = 1 ]; then
                    exit_error "The file cannot be read, check the path and try again!"
                else
                    echo ""
                    echo -e "${GC}[+]${NC} Exclusion file is readable, excluding the following additional IP addresses from the scan:${NC}"
                    echo ""
                    cat $EXCLUDEDIPS |tee .excludeiplist
                    echo ""
                    echo "$ipaddress" >> .excludeiplist
                fi
            fi
        fi
    else
        EXCLUDE="--exclude "$ipaddress""
        echo "$ipaddress" > .excludeiplist
    fi
    
    EXIP=$(cat .excludeiplist)
    EXCLUDE="--excludefile .excludeiplist"
    echo "$EXCLUDE" > .excludetmp
    echo "$ipaddress" >> .excludetmp
    echo -e "${GC}[*]${NC} The following IP addresses were asked to be excluded from the scan = "$EXIP"${NC}" > "$PROJECT"_nmap_hosts_excluded.txt

else
    EXCLUDE="--exclude "$ipaddress""
    echo "$ipaddress" > .excludeiplist
fi

echo $RANGE |egrep '[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}.' &>/dev/null

if [ $? = 0 ]; then

    title_message

    echo ""		
    echo -e "${GC}[+]${NC} Output Dir:\t${GC}$PROJECT${NC}"
    echo -e "${GC}[+]${NC} Interface:\t${GC}$INT${NC}"
    echo -e "${GC}[+]${NC} Targets:\t${GC}$RANGE${NC}"        
    echo -e "${GC}[+]${NC} Exclude:\t${GC}"$(echo ${EXCLUDE} | cut -d ' ' -f2)"${NC}"
    echo -e "${GC}[*]${NC} Finding Live hosts..."
    
    nmap -e $INT  --stats-every 4s -n -PE -PM -PS21,22,23,25,26,53,80,81,110,111,113,135,139,143,179,199,443,445,465,514,548,554,587,993,995,1025,1026,1433,1720,1723,2000,2001,3306,3389,5060,5900,6001,8000,8080,8443,8888,10000,32768,49152 -PA21,80,443,13306 -vvv -sn $EXCLUDE -oA "$PROJECT"_nmap_Finder $RANGE &>/dev/null &    
    sleep 1
    
    grep "QUITTING!" "${PROJECT}_nmap_Finder.nmap" &>/dev/null
    
    if [ $? = 0 ]; then
        exit_error "NMap Error."
    fi
    
    sleep 4
    until [ "$STATUS" = "success" ]; do
        PERCENT=`cat "$PROJECT"_nmap_Finder.xml 2>/dev/null |grep "percent" |cut -d '"' -f 6 |tail -1 |cut -d "." -f 1`
        STATUS=`cat "$PROJECT"_nmap_Finder.xml 2>/dev/null |grep -i "exit" |cut -d '"' -f 10`

        progressbar && spin

        # do work
        sleep 0.2
	done

    endspin


    cat "$PROJECT"_nmap_Finder.gnmap 2>/dev/null | grep "Up" |awk '{print $2}' > "$PROJECT"_hosts_Up.txt
    cat "$PROJECT"_nmap_Finder.gnmap 2>/dev/null | grep  "Down" |awk '{print $2}' > "$PROJECT"_hosts_Down.txt

    printf "\r${GC}[+] ${NC}Scan is 100%% complete"
    echo ""
else
    echo -e "${GC}[*]${NC} You entered a file as the input, checking readability${NC}"
    RANGE=$(echo ${RANGE} | sed -e 's?~?/root?g')    
    cat ${RANGE} &>/dev/null
    
    if [ $? = 1 ]; then
        exit_error "The input file is not readable, check the path and try again."
    else
        echo -e "${GC}[+]${NC} File is readable. Scan will now start${NC}"
        echo -e "${GC}[*]${NC} $PROJECT - Finding Live hosts via $INT, please wait...${NC}"
        nmap -e $INT -sn $EXCLUDE -n --stats-every 4 -PE -PM -PS21,22,23,25,26,53,80,81,110,111,113,135,139,143,179,199,443,445,465,514,548,554,587,993,995,1025,1026,1433,1720,1723,2000,2001,3306,3389,5060,5900,6001,8000,8080,8443,8888,10000,32768,49152 -PA21,80,443,13306 -vvv -oA "$PROJECT"_nmap_Finder -iL $RANGE &>/dev/null &
        sleep 5
        until [ "$STATUS" = "success" ]; do
            PERCENT=`cat "$PROJECT"_nmap_Finder.xml 2>/dev/null |grep "percent" |cut -d '"' -f 6 |tail -1 |cut -d "." -f 1`
            STATUS=`cat "$PROJECT"_nmap_Finder.xml 2>/dev/null |grep -i "exit" |cut -d '"' -f 10`

            progressbar && spin

            # do work
            sleep 0.2
        done

        endspin

        cat "$PROJECT"_nmap_Finder.gnmap 2>/dev/null | grep "Up" |awk '{print $2}' > "$PROJECT"_hosts_Up.txt
        cat "$PROJECT"_nmap_Finder.gnmap 2>/dev/null | grep  "Down" |awk '{print $2}' > "$PROJECT"_hosts_Down.txt
        
        echo -e "${GC}[+]${NC} Scan is 100% complete"
    fi
fi

HOSTSCOUNT=$(cat "$PROJECT"_hosts_Up.txt |wc -l)
HOSTSDOWNCHK=$(cat "$PROJECT"_hosts_Down.txt)

if [ -n "$HOSTSDOWNCHK" ]; then
    echo -e "${RC}[!]${NC} It seems there are some hosts down in the range specified."
    echo -e "${GC}[*]${NC} Running an arp-scan to double check."    
    
    sleep 4
    
    arp-scan --interface $INT --file "$PROJECT"_hosts_Down.txt > "$PROJECT"_arp_Finder.txt 2>&1
    
    cat "$PROJECT"_arp_Finder.txt |grep -i "0 responded" &>/dev/null
    
    if [ $? = 0 ]; then
        echo -e "${RC}[!]${NC} No additional hosts were found using arp-scan."
    else #bkd
        COUNT=$(cat ${PROJECT}_arp_Finder.txt | grep -v Interface | grep -v Starting | grep -v received | grep -v Ending | grep . | cut -d $'\t' -f1 | wc -l)
        
        echo -e "${GC}[*]${NC} ${COUNT} new hosts found with arp-scan."
        grep -v Interface "$PROJECT"_arp_Finder.txt | grep -v Starting | grep -v received | grep -v Ending | grep . | cut -d $'\t' -f1 >> "$PROJECT"_hosts_Up.txt
        echo -e "${GC}[*]${NC} Added to ${PROJECT}_hosts_Up.txt"        
    fi
fi

HOSTSUP=$(cat "$PROJECT"_hosts_Up.txt)

#echo -e "${GC}$HOSTSUP${NC}"

PINGTIMESTART=`cat "$PROJECT"_nmap_Finder.nmap 2>/dev/null |grep -i "scan initiated" | awk '{ print $6 ,$7 ,$8, $9, $10}'`
PINGTIMESTOP=`cat "$PROJECT"_nmap_Finder.nmap 2>/dev/null |grep -i "nmap done" | awk '{ print $5, $6 ,$7 , $8, $9}'`

if [ -z "$PINGTIMESTOP" ]; then
    echo "" >> "$PROJECT"_nmap_scan_times.txt
    echo -e "${RC}[!]${NC} $0 started $PINGTIMESTART${NC} - ${RC}scan did not complete or was interrupted!${NC}"
    echo "[!] $0 started $PINGTIMESTART - scan did not complete or was interrupted!" >> "$PROJECT"_nmap_scan_times.txt
else
    echo "" >> "$PROJECT"_nmap_scan_times.txt
    echo -e "${GC}[+]${NC} Finder finished successfully ${GC}$PINGTIMESTOP${NC}"
    echo "Ping sweep started $PINGTIMESTART - finished successfully $PINGTIMESTOP" >> "$PROJECT"_nmap_scan_times.txt
fi

echo -e "${GC}[+]${NC} Scan is 100% complete"

echo -e "${GC}[+]${NC} HTML report generated: ${GC}${PROJECT}/${PROJECT}_Finder.html${NC}"
echo -e "${GC}[*]${NC} R3D 734M FINDER is complete.${NC}"        
echo ""

#clean up
rm ".excludeiplist" 2>/dev/null
rm  ".excludetmp" 2>/dev/null

exit 0
