#!/bin/bash
######################################################################
#        Name: gatherer.sh
# Description: Gatherer does an intense nmap scan on all hosts that are up. This is a slow scan.
# Output: output/*_AllInfo.gnmap
#   ASCII-ART: http://patorjk.com/software/taag/#p=display&f=ANSI%20Shadow&t=RED%20TEAM%0AGATHERER
######################################################################

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
    echo -e "${BC}###################################################${NC}"    
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

title_message

cd ../$PROJECT
if [ $? = 1 ]; then
    exit_error "Can't find the ${PROJECT} directory."
fi

cd $OUT
if [ $? = 1 ]; then
    exit_error "Can't find the ${PROJECT}/${OUT} directory."
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

UP=$(cat ${PROJECT}_hosts_Up.txt 2>&1)
if [ $? = 1 ]; then
    exit_error "The file ${PROJECT}/${OUT}/${PROJECT}_hosts_Up.txt was not found.  Check the path and try again!"
fi

echo -e "${GC}[+]${NC} nmap -e $INT --stats-every 4s -Pn -sV --version-intensity 0 -p 1-65535 -vvv -O -T4 -A -oA "$PROJECT"_nmap_AllInfo -iL ${PROJECT}_hosts_Up.txt"
echo -e "${GC}[*]${NC} Gathering Host Information..."

nmap -e $INT --stats-every 4s -Pn -sV --version-intensity 0 -p 1-65535 -vvv -O -T4 -A -oA "$PROJECT"_nmap_AllInfo -iL ${PROJECT}_hosts_Up.txt &>/dev/null &

sleep 5
until [ "$STATUS" = "success" ]; do
    PERCENT=`cat "$PROJECT"_nmap_AllInfo.xml 2>/dev/null |grep "percent" |cut -d '"' -f 6 |tail -1 |cut -d "." -f 1`
    STATUS=`cat "$PROJECT"_nmap_AllInfo.xml 2>/dev/null |grep -i "exit" |cut -d '"' -f 10`

    progressbar && spin

    # do work
    sleep 0.2
done

endspin

echo ""
echo -e "${GC}[+]${NC} Scan is 100% complete"

/usr/bin/xsltproc ${PROJECT}_nmap_AllInfo.xml -o ../${PROJECT}_AllInfo.html

echo -e "${GC}[+]${NC} HTML report generated: ${GC}${PROJECT}/${PROJECT}_AllInfo.html${NC}"
echo -e "${GC}[+]${NC} R3D 734M Gatherer is complete." 
echo ""

exit 0
