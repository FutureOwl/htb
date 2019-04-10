#!/bin/bash
######################################################################
#        Name: rpcinfo.sh
# Description: RPCInfo runs rpcinfo on machines that have port 111 open
# Output: *_rpcinfo_*.txt
#   ASCII-ART: http://patorjk.com/software/taag/#p=display&f=ANSI%20Shadow&t=RED%20TEAM%0A%20%20Buster
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
    echo -e "${BC}##################################################${NC}"       
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

UP=$(cat ../$PROJECT/${OUT}/${PROJECT}_hosts_Up.txt 2>/dev/null)
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

title_message
echo ""
cat *Info.gnmap &>/dev/null
if [ $? = 1 ]; then
  exit_error "${PROJECT}/${OUT}/*Info.gnmap was not found."
fi

rm _ENUM 2>/dev/null
rm _ENUMT 2>/dev/null
sleep 1

grep ' 111/open' *Info.gnmap | cut -d " " -f 2 | sort | uniq > _ENUMT

cat _ENUMT | sort | uniq > _ENUM
rm _ENUMT 2>/dev/null
for name in $(cat _ENUM); do
    setterm -cursor off
    echo -ne "${GC}[+]${NC} Gathering RPCInfo for $name..."        
    /usr/sbin/rpcinfo -p $name > ../${PROJECT}_rpcinfo_${name}.txt
    echo "Done."
    echo -e "${GC}[+]${NC} TXT report generated: ${GC}${PROJECT}/${PROJECT}_rpcinfo_${name}.txt${NC}"    
done
rm _ENUM 2>/dev/null

echo -e "${GC}[+]${NC} R3D 734M RPCInfo is complete."

exit 0
