#!/bin/bash

#Game        : The Lost Treausres of Infocom I
#
#Source      : Archive / CD image
#
#Runner      : Scummvm / DOSbox
#
#Description : This script will extract the Archived ISO into ROMs/scummvm or ROMs/dos folder .
#              1: Get Game file(s) either an Archive or CD image 
#              2: Create Game folder in ROMS/scummvm using SCUMMVM_NAME with the extention scummvm (ESDE needs this)
#              3: Extract Game Archive then ISO


#Constants
ROMs_FOLDER_SCUMMVM="$HOME/Games/ROMs/scummvm"
ROMs_FOLDER_DOSBOX="$HOME/Games/ROMs/dos"
TEMP_FOLDER="$HOME/Games/ROMs/scummvm/imstall-script-temp"
              #DISPLAY NAME,  #GAME NAME , SCUMMVM_NAME,  FILE_FILTER, CONF_URL
ELEMENT_1=("Ballyhoo" "ballyhoo.scummvm" "ballyhoo" "-ir!BALLYHOO.DAT" "")
ELEMENT_2=("Beyond Zork - The Coconut of Quendor" "beyondzork.scummvm" "beyondzork" "-ir!BEYONDZO.DAT" "")
ELEMENT_3=("Deadline" "deadline.scummvm" "deadline" "-ir!DEADLINE.DAT" "")
ELEMENT_4=("Enchanter" "enchanter.scummvm" "enchanter" "-ir!ENCHANTE.DAT" "")
ELEMENT_5=("The Hitchhikers Guide to the Galaxy" "hhgttg.scummvm" "hhgttg" "-ir!HITCHHIK.DAT" "")
ELEMENT_6=("Infidel" "infidel.scummvm" "infidel" "-ir!INFIDEL.DAT" "")
ELEMENT_7=("Lurking Horror" "lurkinghorror.scummvm" "lurkinghorror" "-ir!LURKING.DAT" "")
ELEMENT_8=("Moonmist" "moonmist.scummvm" "moonmist" "-ir!MOONMIST.DAT" "")
ELEMENT_9=("Planetfall" "planetfall.scummvm" "planetfall" "-ir!PLANETFA.DAT" "")
ELEMENT_10=("Sorcerer" "sorcerer.scummvm" "sorcerer" "-ir!SORCERER.DAT" "")
ELEMENT_11=("Spellbreaker" "spellbreaker.scummvm" "spellbreaker" "-ir!SPELLBRE.DAT" "")
ELEMENT_12=("Starcross" "starcross.scummvm" "starcross" "-ir!STARCROS.DAT" "")
ELEMENT_13=("Stationfall" "stationfall.scummvm" "stationfall" "-ir!STATIONF.DAT" "")
ELEMENT_14=("Suspect" "suspect.scummvm" "suspect" "-ir!SUSPECT.DAT" "")
ELEMENT_15=("Suspended" "suspended.scummvm" "suspended" "-ir!SUSPEND.DAT" "")
ELEMENT_16=("The Witness" "thewitness.scummvm" "thewitness" "-ir!WITNESS.DAT" "")
ELEMENT_17=("Zork I" "zork1.scummvm" "zork1" "-ir!ZORK1.DAT" "")
ELEMENT_18=("Zork II" "zork2.scummvm" "zork2" "-ir!ZORK2.DAT" "")
ELEMENT_19=("Zork III" "zork3.scummvm" "zork3" "-ir!ZORK3.DAT" "")
ELEMENT_20=("Zork III" "zork3.scummvm" "zork2" "-ir!ZORK2.DAT" "")
ELEMENT_21=("Zork Zero - The Revenge of Megaboz" 
            "zork-zero-the-revenge-of-megaboz.conf" 
            "dosbox" 
            "-ir!ZORK0.CG1 -ir!ZORK0.EG1 -ir!ZORKZERO.EXE -ir!ZORK0.ZIP" 
            "https://raw.githubusercontent.com/appoloin/bash-scripts/refs/heads/main/DOS/lost-treasures-of-infocom/zork-zero-the-revenge-of-megaboz.conf")




GAME_DATA=(
    ELEMENT_1[@]
    ELEMENT_2[@]
    ELEMENT_3[@]
    ELEMENT_4[@]
    ELEMENT_5[@]
    ELEMENT_6[@]
    ELEMENT_7[@]
    ELEMENT_8[@]
    ELEMENT_9[@]
    ELEMENT_10[@]
    ELEMENT_11[@]
    ELEMENT_12[@]
    ELEMENT_13[@]
    ELEMENT_14[@]
    ELEMENT_15[@]
    ELEMENT_16[@]
    ELEMENT_17[@]
    ELEMENT_18[@]
    ELEMENT_19[@]
    ELEMENT_20[@]
    ELEMENT_21[@]
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



select_iso() {
    #Get ONLY ONE file
    local FILE
    local ARCHIVE_MIME='^application/(iso-image|x-cd-image|x-iso9660-image)$'

    FILE=$(zenity --file-selection \
                  --title="Select Game ISO" \
                  --width=800 \
                  --height=500 \
                  --filename="$HOME/Downloads" \
                  --file-filter="CD Image | *.iso")

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



get_game_list (){
    local ARGS=()

    ARGS=()
    for RECORD in "${GAME_DATA[@]}"; do
        ELEMENT=("${!RECORD}") # Get the elements of the sub-array
        ARGS+=("TRUE" "${ELEMENT[0]}")
    done

    # Get list of games to install
    SELECTED=$(zenity  --list \
                        --title="Select Options" \
                        --text="Choose games to install:" \
                        --checklist \
                        --width=800 \
                        --height=500 \
                        --column="Select" \
                        --column="Option" \
                        "${ARGS[@]}")

    # Exit if the user cancels
    if [ $? -ne 0 ]; then
        echo "User cancelled the dialog."
        exit 1
    fi

    # Convert the Zenity output into a Bash array
    IFS='|' read -ra CHOSEN_GAMES <<< "$SELECTED"

    return 0
}



get_source_type () {
    # Show the radio dialog
    local SELECTED
    SELECTED=$(zenity --list \
                      --radiolist \
                      --title="Select Source Type" \
                      --text="Choose source of game files:" \
                      --column="Select" \
                      --column="Source" \
                      FALSE "ISO" \
                      FALSE "Archive" )
    

    # Check if user canceled
    if [ $? -ne 0 ]; then 
        return 1 
    fi

    case "$SELECTED" in
        "ISO")
            RADIO_OPTION=1
            ;;
        "Archive")
            RADIO_OPTION=2
            ;;
        *)
            echo "Unknown selection: $SELECTED"
            RADIO_OPTION=0
            return 1
            ;;
    esac

}


#extract archive  
#"$1" URL
#"S2" Output Path
#"S3" Output filename
download_file() {
    local URL="$1"
    local OUTPUT_PATH="$2"
    local OUTPUT_NAME="$3"  # Optional: Custom output filename

    # Download the file
    if [ -n "$OUTPUT_NAME" ]; then
        # If a custom output filename is provided
        wget -q -P "$OUTPUT_PATH" -O "$OUTPUT_PATH/$OUTPUT_NAME" "$URL"
    else
        # Default: Use the original filename
        wget -q -P "$OUTPUT_PATH" "$URL"
    fi

    # Check if wget succeeded
    if [ $? -ne 0 ]; then
        zenity --error --text="Failed to download \nCheck the URL or your internet connection."
        return 1
    fi
}



main(){

    local EXE_PATH=""
    local FILE=""

    get_game_list
    if [ $? -ne 0 ]; then
        echo "Error no games selected"
        exit 1
    fi

    get_source_type
    if [ $? -ne 0 ]; then
        echo "Error Selecting File"
        exit 1
    fi

    if [[ $RADIO_OPTION -le 0 ]]; then
        echo "Selected: $RADIO_OPTION"
        zenity --error --text="Error: Selction Unknown : $RADIO_OPTION"
        exit 1
    elif  [[ $RADIO_OPTION -eq 1 ]]; then #ISO

        select_iso
        if [ $? -ne 0 ]; then
            echo "Error Selecting File"
            exit 1
        fi

        EXE_PATH=$FILES

    elif  [[ $RADIO_OPTION -eq 2 ]]; then #Archive

        select_archive  #Get Archive location
        if [ $? -ne 0 ]; then
            echo "Error Selecting File"
            exit 1
        fi

        zenity --notification --text="Starting Extraction" --title="Game Install"

        extract_archive "$FILES" "$TEMP_FOLDER" "e"
        if [ $? -ne 0 ]; then 
            #remove Game folder
            rm -f -r "$TEMP_FOLDER"
            exit 1
        fi


        FILE=$(find "$TEMP_FOLDER" -type f -iname "*.iso" | head -n 1)

        EXE_PATH="$FILE"
    fi    

    zenity --notification --text="Extracting files from iso" --title="Game Install"
    for item in "${CHOSEN_GAMES[@]}"; do
        echo "Selected: $item"
        for RECORD in "${GAME_DATA[@]}"; do
            ELEMENT=("${!RECORD}") # Get the elements of the sub-array
            DISPLAY_NAME="${ELEMENT[0]}"
            GAME_NAME="${ELEMENT[1]}"
            SCUMMVM_NAME="${ELEMENT[2]}"
            FILE_FILTER="${ELEMENT[3]}"
            CONF_FILE_URL="${ELEMENT[4]}"

            if [[ "$item" == "$DISPLAY_NAME" ]]; then
                echo "Found $DISPLAY_NAME Filter = $FILE_FILTER"
                
                if [[ "$SCUMMVM_NAME" == "dosbox" ]]; then #install into dosbox folder
                    mkdir "$ROMs_FOLDER_DOSBOX/$GAME_NAME"
                    extract_archive "$EXE_PATH" "$ROMs_FOLDER_DOSBOX/$GAME_NAME/" "e" "$FILE_FILTER"
                    if [ $? -ne 0 ]; then 
                        #remove Game folder from ROMs/dox directory
                        zenity --error --text="Error: Archive extraction failed \n$EXE_PATH"
                        rm -f -r "$ROMs_FOLDER_DOSBOX/$GAME_NAME"
                        exit 1
                    fi    
                    zenity --notification --text="Extraction complete" --title="Game Install"

                    #Download conf file from github
                    download_file "$CONF_FILE_URL"  "$ROMs_FOLDER_DOSBOX/$GAME_NAME" "$GAME_NAME"
                    # Check if wget succeeded
                    if [ $? -ne 0 ]; then
                        echo "Failed to download: '$CONF_FILE_URL'"
                        zenity --error --text="Error: Conf download failed \n$CONF_FILE_URL"
                        rm -f -r "$ROMs_FOLDER_DOSBOX/$GAME_NAME"
                        exit 1
                    fi
                else #install in to scummvm folder
                    mkdir "$ROMs_FOLDER_SCUMMVM/$GAME_NAME"
                    extract_archive "$EXE_PATH" "$ROMs_FOLDER_SCUMMVM/$GAME_NAME" "e" "$FILE_FILTER"
                    if [ $? -ne 0 ]; then 
                        #remove Game folder
                        rm -f -r "$ROMs_FOLDER_SCUMMVM/$GAME_NAME"
                        exit 1
                    fi

                    #Create ES_DE launch file with engine code
                    echo "$SCUMMVM_NAME" > "$ROMs_FOLDER_SCUMMVM/$GAME_NAME/$GAME_NAME"
                fi
                break
            fi
        done
    done

    #Cleam up temp folder
    if [ -d  "$TEMP_FOLDER" ]; then
        rm -f -r "$TEMP_FOLDER"
    fi

    zenity --notification --text="Game install complete" --title="Game Install"
}




main

exit