#!/bin/bash

#Game        : Battle Chess
#
#Source      : GOG installer
#
#Runner      : DosBox
#
#Description : This script will extract the GOG installer into ROMs/dos folder .
#              1: Get Game file
#              2: Create Game folder in ROMS/dos add conf extention to folder name (ESDE needs this)
#              3: Extract Game Archive if used
#              4: Download conf file from github

#Constants
ROMs_FOLDER="$HOME/Games/ROMs/dos"
INNO_URL="https://www.dropbox.com/scl/fi/j0fpcie1r4afohmdjw2yb/innoextract-1.9.7z?rlkey=i0n1k54rr69n7ccosapvmmqbc&st=xqrri3av&dl=1"
INNO_ARCHIVE_NAME="innoextract-1.9.7z"
INNO_EXE="innoextract"
TEMP_FOLDER="$ROMs_FOLDER/temp"


            #DISPLAY NAME,  #GAME NAME ,  #FILE_FILTER, #CONF_URL
ELEMENT_1=("Battle Chess" 
           "battle-chess.conf" 
           "Battle Chess" 
           "https://raw.githubusercontent.com/appoloin/bash-scripts/refs/heads/main/DOS/battle-chess/battle-chess.conf")
ELEMENT_2=("Battle Chess 4000" 
           "battle-chess-4000.conf" 
           "Battle Chess 4000" 
           "https://raw.githubusercontent.com/appoloin/bash-scripts/refs/heads/main/DOS/battle-chess/battle-chess-4000.conf")
ELEMENT_3=("Chinese Chess" 
           "chinese-chess.conf" 
           "Chinese Chess" 
           "https://raw.githubusercontent.com/appoloin/bash-scripts/refs/heads/main/DOS/battle-chess/chinese-chess.conf")

GAME_DATA=(
    ELEMENT_1[@]
    ELEMENT_2[@]
    ELEMENT_3[@]
)




#Global
FILES=""  #Game File Location
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


# Build list of games to install
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




#GET Location of CD images iso, cue/bin
select_exe_installer() {
    # Use zenity to select files
    local files
    files=$(zenity --file-selection \
                   --width=800 \
                   --height=500 \
                   --filename="$HOME/Downloads" \
                   --title="Select GOG EXE Installer" \
                   --file-filter="GOG Installer | *.exe" )

    # Exit if user cancels
    if [ $? -ne 0 ]; then
        return 1
    fi

    # Return the selected files
    FILES="$files"
}




main(){

    select_exe_installer  
    if [ $? -ne 0 ]; then
        echo "Error Selecting File"
        exit 1
    fi

    get_game_list
    if [ $? -ne 0 ]; then
        echo "Error no games selected"
        exit 1
    fi

    zenity --notification --text="Installing game" --title="Game Install"

    mkdir -p "$TEMP_FOLDER"
   
    #get innoextract archive from dropbox
    download_file "$INNO_URL" "$TEMP_FOLDER" "$INNO_ARCHIVE_NAME" 
    # Check if wget succeeded
    if [ $? -ne 0 ]; then
        rm -f -r "$TEMP_FOLDER"
        exit 1
    fi

    #extract to ROMs/pc/Game folder/temp  
    extract_archive "$TEMP_FOLDER/$INNO_ARCHIVE_NAME" "$TEMP_FOLDER" "x"
    if [ $? -ne 0 ]; then
        zenity --error --text="Error: Innoextract extraction failed."
        rm -f -r "$TEMP_FOLDER"
        exit 1
    fi

    zenity --notification --text="Run Innoextract" --title="Game Install"
    $TEMP_FOLDER/$INNO_EXE -d "$TEMP_FOLDER" "$FILES"
    if [ $? -ne 0 ]; then
        echo "Failed to extract EXE: '$FILES'"
        zenity --error --text="Error: Innoextract extraction of game exe failed \n'$FILES'."
        rm -f -r "$TEMP_FOLDER"
        exit 1
    fi


    for item in "${CHOSEN_GAMES[@]}"; do
        echo "Selected: $item"
        for RECORD in "${GAME_DATA[@]}"; do
            ELEMENT=("${!RECORD}") # Get the elements of the sub-array
            DISPLAY_NAME="${ELEMENT[0]}"
            GAME_NAME="${ELEMENT[1]}"
            FILE_FILTER="${ELEMENT[2]}"
            CONF_FILE_URL="${ELEMENT[3]}"

            if [[ "$item" == "$DISPLAY_NAME" ]]; then
                echo "Found $DISPLAY_NAME Filter = $FILE_FILTER"
                
                #copy files to correct game folder
                find "$TEMP_FOLDER/app" -mindepth 1 -maxdepth 1 -name "$FILE_FILTER"  -exec cp {} -r "$ROMs_FOLDER/$GAME_NAME" \;

                #Download conf file from github
                download_file "$CONF_FILE_URL"  "$ROMs_FOLDER/$GAME_NAME" "$GAME_NAME"
                # Check if wget succeeded
                if [ $? -ne 0 ]; then
                    echo "Failed to download: '$CONF_FILE_URL'"
                    zenity --error --text="Error: Conf download failed \n$CONF_FILE_URL"
                    rm -f -r "$ROMs_FOLDER_DOSBOX/$GAME_NAME"
                    exit 1
                fi

                touch "$ROMs_FOLDER/$GAME_NAME/noload.txt"

            fi
        done
    done

    #Clean up
    rm -f -r "$TEMP_FOLDER"

    zenity --notification --text="Game install complete" --title="Game Install"
}




main

exit