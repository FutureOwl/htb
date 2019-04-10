#!/bin/bash

#Last updated 8/24/2016 7:40AM by David Hritz
# * Added python, perl, and ruby support

BC="\e[00;30m" #black color
RC="\e[1;31m" #red color
GC="\e[1;32m" #green color
NC="\e[00m" #no color
CC="\e[1;34m" #blue color
YC="\e[1;33m" #yellow color

rm -f _bin/.PROJECT &>/dev/null
rm -f _bin/.INT &>/dev/null

title_message()
{
    if [ -z $1 ]; then 
        clear
    fi
    
    echo -e "${BC}Welcome to the Enumeration Portal${NC}"    
}

title_message

script_menu() #IN PROGRESS
{        
    declare -a script_arr
    
    if [ -n "$2" ]; then 
        title_message nc
    else 
        title_message
    fi
    
    echo ""
    
    SCRIPT_COUNT=$(\ls _bin/*.{sh,py,pl,rb} 2>/dev/null | xargs -n1 basename 2>/dev/null | wc -l)
    
    if [ $SCRIPT_COUNT -gt 0 ]; then
        echo -e "Welcome to the ${RC}R3D ${BC}734M 3NUM3R473${NC} Script Chooser! Current project is ${RC}${CURRENT_PROJECT}${NC}. ${GC}Green${NC} indicates script has already been run.${NC}"
        echo ""
        echo -e "${YC}[0]${NC} Back to main menu"
    else 
        echo -e "${RC}[!]${NC} No scripts found in the _bin directory. Please add scripts, and pretty please - ${RC}quit failing! N00b${NC}"
        echo ""
        exit 0
    fi
    
    COUNTER=1
    TAB=""
    FULL_SCRIPT_NAME=""
    SCRIPT_DESC=""
    SAVEIFS=$IFS
    IFS=$(echo -en "\n\b")
    for i in $(ls _bin/*.{sh,py,pl,rb} 2>/dev/null | xargs -n1 basename 2>/dev/null); do
        script_arr[COUNTER]=$i
        FULL_SCRIPT_NAME=$i
        
        SCRIPT_NAME="$(echo -e ${FULL_SCRIPT_NAME} | sed -e 's/^[[:digit:]]\{1,5\}_//g' | sed -E -e 's/\.sh$|\.py$|\.rb$|\.pl$//g')"
        COMPLETED_SCRIPT="${YC}[${COUNTER}]${NC} ${GC}$SCRIPT_NAME${NC}"    
        SCRIPT_NAME="${YC}[${COUNTER}]${NC} $SCRIPT_NAME"
        LENGTH=${#SCRIPT_NAME}
      
        if [ $LENGTH -gt 28 ]; then
            TAB="\t"
        else
            TAB="\t\t"
        fi
        
        OUTPUT=$(grep Output: _bin/${FULL_SCRIPT_NAME} | cut -d ":" -f2 | sed -e 's/^[ \t]*//')
        
        if [[ ! -z "${OUTPUT// }" ]]; then #if output field exists in header
            ls ${CURRENT_PROJECT}/${OUTPUT} &>/dev/null 
            if [ $? == 0 ]; then
                echo -e "$COMPLETED_SCRIPT $TAB"$(grep Description: _bin/${FULL_SCRIPT_NAME} | cut -d ":" -f2 | sed -e 's/^[ \t]*//')
            else 
                echo -e "$SCRIPT_NAME $TAB"$(grep Description: _bin/${FULL_SCRIPT_NAME} | cut -d ":" -f2 | sed -e 's/^[ \t]*//')
            fi
        else 
            echo -e "$SCRIPT_NAME $TAB"$(grep Description: _bin/${FULL_SCRIPT_NAME} | cut -d ":" -f2 | sed -e 's/^[ \t]*//')
        fi
                               
        let COUNTER=COUNTER+1
    done
    IFS=$SAVEIFS   
    
    echo ""
    
    choice=""
    noob_counter=0
    while [[ -z ${script_arr[$choice]} ]]; do
    
        if [ $noob_counter -eq 5 ]; then
            echo -e "${RC}DO YOU NOT UNDERSTAND ENGLISH? ¿Hablas español? N00b${NC}"
            echo ""
            exit 0
        fi
        
        read -p "$(echo -e ${CC}"[?]"${NC}" Which script would you like to choose [ 1 - ${SCRIPT_COUNT} ]? ")" choice
        
        if [[ ! ${choice} =~ ^[0-9]+$ ]]; then
            echo ""
            echo -e "${RC}[!]${NC} Invalid string input. Choose a valid number for the love of R3D 734M.. N00b"
            echo ""
            let noob_counter=noob_counter+1
            continue
        fi
        
        if [[ choice -eq 0 ]]; then
            return 25
        fi
    
        if [ -z "${script_arr[$choice]}" ]; then
            echo ""
            echo -e "${RC}[!]${NC} Invalid script number chosen. Choose again... N00b"
            echo ""
        fi 
        let noob_counter=noob_counter+1
    done  
    
    SCRIPT_TO_RUN=${script_arr[$choice]}
    
    cd _bin
    
    # find file extension... call appropriate.....
    EXTENSION="${SCRIPT_TO_RUN##*.}"
    UEXTENSION=$(echo $EXTENSION | awk '{print toupper($0)}')
    
    if [ $UEXTENSION=="SH" ]; then
        ./${SCRIPT_TO_RUN}
    elif [ $UEXTENSION=="PY" ]; then
        /usr/bin/python ${SCRIPT_TO_RUN}
    elif [ $UEXTENSION=="PL" ]; then
        /usr/bin/perl ${SCRIPT_TO_RUN}
    elif [ $UEXTENSION=="RB" ]; then
       /usr/bin/ruby ${SCRIPT_TO_RUN} 
    else
        echo ""
        echo -e "${RC}[!]${NC} N00b. Run again because you fail. Exiting...${NC}"
        echo ""
        exit 0
    fi   
    
    if [ $? != 0 ]; then
        echo ""
        echo -e "${RC}[!]${NC} N00b. Run again because you fail. Exiting...${NC}"
        echo ""
        exit 0
    else 
        cd ..
        script_menu $CURRENT_PROJECT 1
    fi
}

archive_menu() #DONE DON'T TOUCH
{
    declare -a project_arr
    
    title_message
    echo ""
    PROJECT_COUNT=$(\ls -d */ | grep -v '^_' | wc -l)
    
    if [ $PROJECT_COUNT -gt 0 ]; then
        echo -e "Welcome to the ${RC}R3D ${BC}734M 3NUM3R473${NC} Archive Tool! Enter a project you would like to archive [ 1 - ${PROJECT_COUNT} ]:"
        echo ""
        if [ -n "$1" ]; then 
            echo -e "$1"
            echo ""
        fi
        echo -e "${YC}[0]${NC} Back to main menu"
    else 
        echo -e "${RC}[!]${NC} No projects found. Please quit being a N00b, and pretty please - ${RC}quit failing! N00b${NC}"
        exit 0
    fi
    
    COUNTER=1
    SAVEIFS=$IFS
    IFS=$(echo -en "\n\b")
    for f in $(ls -d */ | grep -v "^[_.]" | rev | cut -c 2- | rev); do
        project_arr[COUNTER]=$f
        echo -e "${YC}[${COUNTER}]${NC} ${f}"
        let COUNTER=COUNTER+1
    done
    IFS=$SAVEIFS    
            
    echo ""
    
    choice=""
    noob_counter=0
    while [[ -z ${project_arr[$choice]} ]]; do
    
        if [ $noob_counter -eq 5 ]; then
            echo -e "${RC}DO YOU NOT UNDERSTAND ENGLISH? ¿Hablas español? N00b${NC}"
            echo ""
            exit 0        
        fi
        
        read -p "$(echo -e ${CC}"[?]"${NC}" Which project would you like to archive [ 1 - ${PROJECT_COUNT} ]? ")" choice
        
        if [[ ! ${choice} =~ ^[0-9]+$ ]]; then
            echo ""
            echo -e "${RC}[!]${NC} Invalid string input. Choose a valid number for the love of R3D 734M.. N00b"
            echo ""
            let noob_counter=noob_counter+1
            continue
        fi
        
        if [[ choice -eq 0 ]]; then
            return 20
        fi
    
        if [ -z "${project_arr[$choice]}" ]; then
            echo ""
            echo -e "${RC}[!]${NC} Invalid project number chosen. Choose again... N00b"
            echo ""
        fi   
        let noob_counter=noob_counter+1
    done
    
    FOLDER_TO_ARCHIVE=${project_arr[$choice]}
    
    if [ -d "_archive" ]; then
        mv "${FOLDER_TO_ARCHIVE}" _archive
    else 
        mkdir _archive
        mv "${FOLDER_TO_ARCHIVE}" _archive
    fi
    
    ARCHIVE_MSG=""
    if [ -d "_archive/${FOLDER_TO_ARCHIVE}" ]; then #successfully moved
        ARCHIVE_MSG="${GC}[*]${NC} Project ${RC}${FOLDER_TO_ARCHIVE}${NC} successfully archived to _archive folder!"
    else
        echo -e "${RC}[!]${NC} Error archiving project. Please try again... N00b"
        exit 0
    fi
    
    archive_menu "${ARCHIVE_MSG}"
}

main_menu()
{

    unset ENUMERATE_PNAME

    echo ""
    echo -e "Welcome to the ${RC}R3D ${BC}734M 3NUM3R473${NC}! Options include:"
    echo -e "${GC}[*]${NC} 'new' or 'n'\tcreate a new project"
    echo -e "${GC}[*]${NC} 'archive' or 'a'\tarchive existing projects"
    echo -e "${GC}[*]${NC} 'project name'\tselect existing project"
    echo -e "${GC}[*]${NC} 'quit' or 'q'\tquit the program"
    echo ""

    # Check if root
    if [[ $EUID -ne 0 ]]; then
        echo ""
        echo -e "${RC}[!]${NC} This program must be run as root. Run again with 'sudo'. Exiting...${NC}"
        echo ""
        exit 0
    fi

    echo -e "Projects detected:"
    SAVEIFS=$IFS
    IFS=$(echo -en "\n\b")
    for i in $(\ls -d */ | grep -v '^_'); do
        echo -e "${YC}[-]${NC} $(echo ${i} | cut -d '/' -f1)" 
    done
    IFS=$SAVEIFS  

    PROJECT_COUNT=$(\ls -d */ | grep -v '^_' | wc -l)

    if [ $PROJECT_COUNT -eq 0 ]; then
        echo -e "${YC}[-]${NC} None"
    fi

    echo ""
    read -e -p "$(echo -e ${CC}"[?]"${NC}" Which option would you like to choose (new)? ")" PROJECT

    if [ -z $PROJECT ]; then
        PROJECT="new"
    fi

    UPROJECT=$(echo $PROJECT | awk '{print toupper($0)}')

    #check for new, then do something
    if [ $UPROJECT == "NEW" ] || [ $UPROJECT == "N" ]; then
    #call finder
    #wait to complete, loop back to enumerate
        rm -f _bin/.PROJECT &>/dev/null
        rm -f _bin/.INT &>/dev/null

        cd _bin
        ./01_finder.sh
        if [ $? != 0 ]; then
            echo ""
            echo -e "${RC}[!]${NC} N00b. Run again because you fail. Exiting...${NC}"
            echo ""
            exit 0
        else 
            CURRENT_PROJECT=$(head -n 1 .project)
            cd ..
            script_menu $CURRENT_PROJECT 1
            title_message
            main_menu 
        fi

    #check for archive, then do something
    elif [ $UPROJECT == "ARCHIVE" ] || [ $UPROJECT == "A" ]; then
        archive_menu
        title_message
        main_menu      

    #check for archive, then do something
    elif [ $UPROJECT == "QUIT" ] || [ $UPROJECT == "Q" ]; then
        exit 0          
       
    #check too see if directory exists    
    elif [ -d "$PROJECT" ]; then
        CURRENT_PROJECT=$PROJECT
        
        if [[ "$CURRENT_PROJECT" == */ ]]; then
            CURRENT_PROJECT=${CURRENT_PROJECT%?}
        fi
        
        echo "${CURRENT_PROJECT}" > _bin/.PROJECT
        script_menu $CURRENT_PROJECT
        title_message
        main_menu 
    
    #invalid command
    else
        echo ""
        echo -e "${RC}[!]${NC} Invalid command entered. Run again because you fail. Try harder.....Exiting...${NC}"
        echo ""
    fi
}

main_menu

exit 0
