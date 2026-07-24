#!/bin/bash

#Game        : Gnome Ranger
#
#Source      : Archive 
#
#Runner      : Scummvm 
#
#Description : This script will extract the Archived ISO into ROMs/scummvm  folder .
#              1: Get Game file(s) either an Archive or CD image 
#              2: Create Game folder in ROMS/scummvm using SCUMMVM_NAME with the extention scummvm (ESDE needs this)
#              3: Extract Game Archive then ISO


#Constants
ROMs_FOLDER_SCUMMVM="$HOME/Games/ROMs/scummvm"
TEMP_FOLDER="$HOME/Games/ROMs/scummvm/imstall-script-temp"
              #DISPLAY NAME,  #GAME NAME , SCUMMVM_NAME,  FILE_FILTER, CONF_URL
ELEMENT_1=("Gnome Part 1" "gnomeranger.scummvm" "gnomeranger" "-ir!GAMEDAT1.DAT -ir!*.PIC" "")
ELEMENT_2=("Gnome Part 2" "gnomeranger-1.scummvm" "gnomeranger-1" "-ir!GAMEDAT2.DAT -ir!*.PIC" "")
ELEMENT_3=("Gnome Part 3" "gnomeranger-2.scummvm" "gnomeranger-2" "-ir!GAMEDAT3.DAT -ir!*.PIC" "")



GAME_DATA=(
    ELEMENT_1[@]
    ELEMENT_2[@]
    ELEMENT_3[@]
)


#Global
FILES=""  #Game File Location
RADIO_OPTION=0 #ISO = 1;  Archive = 2
CHOSEN_GAMES=() #array of chosen games

#extract archive  
#"$1" Archive Path
#"S2" Output Path
#"S3" Extract with (x) or Without Path (e) 
#"$4" EXtract these files OPTIONAL
#"S4" Password OPTIONAL
extract_archive() {
    local ARCHIVE_PATH="$1"
    local OUTPUT="$2"
    local EXTRACT_METHOD="$3"
    local EXTRACT_PATTERN="$4"  #OPTIONAL : -ir!pattern
    local PASSWORD="$5"  # Optional: Password for encrypted archives

    # Check if the archive file exists
    if [ ! -f "$ARCHIVE_PATH" ]; then
        zenity --error --text="Archive not found: $ARCHIVE_PATH"
        return 1
    fi

    # Extract the archive
    if [[ "${EXTRACT_METHOD,,}" == "e" ]]; then 
        #no paths
        if [ -n "$PASSWORD" ]; then
            # If a password is provided, use it for extraction
            7z e -p"$PASSWORD" "$ARCHIVE_PATH" -o"$OUTPUT" $EXTRACT_PATTERN -y
        else
            # Extract without a password
            7z e "$ARCHIVE_PATH" -o"$OUTPUT" $EXTRACT_PATTERN -y
        fi
    else       
        #extract with paths                        
        if [ -n "$PASSWORD" ]; then
            # If a password is provided, use it for extraction
            7z x -p"$PASSWORD" "$ARCHIVE_PATH" -o"$OUTPUT" $EXTRACT_PATTERN -y
        else
            # Extract without a password
            7z x "$ARCHIVE_PATH" -o"$OUTPUT" $EXTRACT_PATTERN -y
        fi
    fi

    # Check the exit status of 7z
    case $? in
        0)
            if [[ "${EXTRACT_METHOD,,}" == "e" ]]; then 
                #no paths
                #Clean up after e extract (ie empty folders)
                find "$OUTPUT" -type d -empty -delete
            fi
            ;;
        1)
            zenity --error --text="Warning: One or more files were not extracted \n$ARCHIVE_PATH"
            return 1
            ;;
        2)
            zenity --error --text="Fatal error: Archive is corrupted or not a valid 7z file. \n$ARCHIVE_PATH"
            return 1
            ;;
        7)
            zenity --error --text="Command-line error: Invalid arguments or syntax."
            return 1
            ;;
        8)
            zenity --error --text="Not enough memory for the operation."
            return 1
            ;;
        9)
            zenity --error --text="Archive is encrypted and no password was provided. \n$ARCHIVE_PATH"
            return 1
            ;;
        *)
            zenity --error --text="Unknown error occurred while extracting the archive. \n$ARCHIVE_PATH"
            return 1
            ;;
    esac
}





#Get the loaction the archive files 
select_archive() {
    #Get ONLY ONE file
    local FILE
    local ARCHIVE_MIME='^application/(zip|x-tar|x-gzip|x-bzip2|x-7z-compressed|x-rar-compressed|x-xz)$'

 FILE=$(zenity --file-selection \
                  --title="Select Game Archive"  \
                  --width=800 \
                  --height=500 \
                  --filename="$HOME/Downloads" \
                  --file-filter="Archive | *.zip *.7z *.rar *.7z.001 *.001 *.zip.001 *.r00")

    # Exit if user cancels
    if [ $? -ne 0 ]; then 
        return 1 
    fi
    
    local MIME_TYPE
    MIME_TYPE=$(file --mime-type -b "$FILE")
    echo "MIME_TYPE $MIME_TYPE"

    # Check file's MIME type
    if [[ ! $MIME_TYPE =~ $ARCHIVE_MIME ]]; then
        echo "Wrong file type selected"
        zenity --error --text="Error: '$FILE' \nis not a valid \n$ARCHIVE_MIME \nfile \n(MIME type: $MIME_TYPE)."
        return 1
    fi

    # Return the selected archive
    FILES="$FILE"
    return 0
}




main(){

    local EXE_PATH=""
    local FILE=""

    select_archive  #Get Archive location
    if [ $? -ne 0 ]; then
        echo "Error Selecting File"
        exit 1
    fi

    zenity --notification --text="Starting Extraction" --title="Game Install"

    for RECORD in "${GAME_DATA[@]}"; do
        ELEMENT=("${!RECORD}") # Get the elements of the sub-array
        DISPLAY_NAME="${ELEMENT[0]}"
        GAME_NAME="${ELEMENT[1]}"
        SCUMMVM_NAME="${ELEMENT[2]}"
        FILE_FILTER="${ELEMENT[3]}"
 
        mkdir "$ROMs_FOLDER_SCUMMVM/$GAME_NAME"
        extract_archive "$FILES" "$ROMs_FOLDER_SCUMMVM/$GAME_NAME" "e" "$FILE_FILTER"
        if [ $? -ne 0 ]; then 
            #remove Game folder
            rm -f -r "$ROMs_FOLDER_SCUMMVM/$GAME_NAME"
            rm -f -r "$TEMP_FOLDER"
            exit 1
        fi

        #Create ES_DE launch file with engine code
        echo "$SCUMMVM_NAME" > "$ROMs_FOLDER_SCUMMVM/$GAME_NAME/$GAME_NAME"
    done

    #Cleam up temp folder
    if [ -d  "$TEMP_FOLDER" ]; then
        rm -f -r "$TEMP_FOLDER"
    fi

    zenity --notification --text="Game install complete" --title="Game Install"
}




main

exit