#!/bin/bash

#Game        : Star Wars - Jedi knight - Jedi Academy
#
#Source      : Archive GOG
#
#Runner      : Linux Port
#
#Description : This script will extract the an Archived ISO into ROMs/ports folder .
#              1: Get Game file
#              2: Create Game folder in ROMS/ports nameed $GME_NAME (ESDE needs this)
#              3: Extract Game files Archive 
#              4: Create sh file and noload file


#Constants
ROMs_FOLDER="$HOME/Games/ROMs/ports"
NAME="star-wars-jedi-knight-jedi-academy"
GAME_NAME="$NAME.sh"
TEMP_FOLDER="$ROMs_FOLDER/$GAME_NAME/temp"
ENGINE_URL="https://www.dropbox.com/scl/fi/canfhrcz9y6gnmn2ctlea/OpenJK-linux-x86_64.tar.gz?rlkey=8mfivi4ztamn6mmo7q4u1cznq&st=3xgcdhj7&dl=1"
ENGINE_NAME="OpenJK-linux-x86_64.tar.gz"
ENGINE_NAME_2="OpenJK-linux-x86_64.tar"
ENGINE_NAME_3="OpenJK-linux-x86_64"
ENGINE_EXE="openjk_sp.x86_64"
INNO_URL="https://www.dropbox.com/scl/fi/j0fpcie1r4afohmdjw2yb/innoextract-1.9.7z?rlkey=i0n1k54rr69n7ccosapvmmqbc&st=xqrri3av&dl=1"
INNO_ARCHIVE_NAME="innoextract-1.9.7z"
INNO_EXE="innoextract"
FILE_FILTER=""



#Global
FILES=""  #Game File Location


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
                  --title="Select Game Archive" \
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


    select_archive  #Get Archive location
    if [ $? -ne 0 ]; then
        echo "Error Selecting File"
        exit 1
    fi

    zenity --notification --text="Starting Extraction" --title="Game Install"

    mkdir -p "$TEMP_FOLDER"

    extract_archive "$FILES" "$TEMP_FOLDER" "e"
    if [ $? -ne 0 ]; then 
        #remove Game folder
        rm -f -r "$ROMs_FOLDER/$GAME_NAME"
        exit 1
    fi

    EXE_PATH=$(find "$TEMP_FOLDER" -type f -iname "*.exe" | head -n 1)

    #Download Engine and Extract
    zenity --notification --text="Downloading and installing engine" --title="Game Install"
    download_file "$ENGINE_URL"  "$TEMP_FOLDER" "$ENGINE_NAME"
    # Check if wget succeeded
    if [ $? -ne 0 ]; then
        echo "Failed to download: '$ENGINE_URL'"
        zenity --error --text="Error: Conf download failed \n$ENGINE_URL"
        rm -f -r "$ROMs_FOLDER/$GAME_NAME"
        exit 1
    fi

    extract_archive "$TEMP_FOLDER/$ENGINE_NAME" "$TEMP_FOLDER" "x" "$FILE_FILTER"
    if [ $? -ne 0 ]; then 
        #remove Game folder
        rm -f -r "$ROMs_FOLDER/$GAME_NAME"
        exit 1
    fi
    extract_archive "$TEMP_FOLDER/$ENGINE_NAME_2" "$ROMs_FOLDER/$GAME_NAME" "x" "$FILE_FILTER"
    if [ $? -ne 0 ]; then 
        #remove Game folder
        rm -f -r "$ROMs_FOLDER/$GAME_NAME"
        exit 1
    fi

    zenity --notification --text="Downloading Innoextract" --title="Game Install" 
    #get innoextract archive from dropbox
    download_file "$INNO_URL" "$TEMP_FOLDER" "$INNO_ARCHIVE_NAME" 
    # Check if wget succeeded
    if [ $? -ne 0 ]; then
        rm -f -r "$ROMs_FOLDER/$GAME_NAME"
        exit 1
    fi

    #extract to ROMs/pc/Game folder/temp  
    extract_archive "$TEMP_FOLDER/$INNO_ARCHIVE_NAME" "$TEMP_FOLDER" "x"
    if [ $? -ne 0 ]; then
        zenity --error --text="Error: Innoextract extract failed."
        rm -f -r "$ROMs_FOLDER/$GAME_NAME"
        exit 1
    fi

    zenity --notification --text="Running Innoextract" --title="Game Install"
    "$TEMP_FOLDER/$INNO_EXE" -d "$TEMP_FOLDER" "$EXE_PATH"
    if [ $? -ne 0 ]; then
        echo "Failed to extract EXE: '$EXE_PATH'"
        zenity --error --text="Error: Innoextract extraction of game exe failed \n'$EXE_PATH'."
        rm -f -r "$ROMs_FOLDER/$GAME_NAME"
        exit 1
    fi
    find "$TEMP_FOLDER/app/GameData/" -mindepth 1 -maxdepth 1 -name "*" -exec cp {} -r "$ROMs_FOLDER/$GAME_NAME" \;

    touch "$ROMs_FOLDER/$GAME_NAME/noload.txt"
    #Create ES_DE launch file with engine code
    echo -e "#!/bin/bash\n\n$ROMs_FOLDER/$GAME_NAME/$ENGINE_EXE" > "$ROMs_FOLDER/$GAME_NAME/$GAME_NAME"

    #Cleam up temp folder
    rm -f -r "$TEMP_FOLDER"
    
    zenity --notification --text="Game install complete" --title="Game Install"
}




main

exit