#!/bin/bash

#Game        : Frankenstein Through The Eyes Of The Monster
#
#Source      : EXO Dox Archive 
#
#Runner      : Dosbox / Win3.11 
#
#Description : This script will create a Window 3.11 bottle and install the Game files.
#              1: Get Game archive 
#              3: Create a sub folder (name defined in CONF_FILE_NAME) in  ES-DE's ROMs folder (path defined in ROMs_FOLDER)
#              5: Extract archive
#              6: Downlaod Dosbox conf file from Github  (url defined in CONF_FILE_URL)


#Constants
ROMs_FOLDER="$HOME/Games/ROMs/windows3x"
CONF_FILE_URL="https://raw.githubusercontent.com/appoloin/bash-scripts/refs/heads/main/Win311/frankenstein-through-the-eyes-of-the-monster/frankenstein-through-the-eyes-of-the-monster.conf"
CONF_FILE_NAME="frankenstein-through-the-eyes-of-the-monster.conf"

#Global
FILES=""  #Game File Location
RADIO_OPTION=0 #CD Image = 1;  Archive = 2


#extract archive  
#"$1" Archive Path
#"S2" Output Path
#"S3" Extract with (x) or Without Path (e) 
#"S4" Password OPTIONAL
extract_archive() {
    local ARCHIVE_PATH="$1"
    local OUTPUT="$2"
    local EXTRACT_METHOD="$3"
    local PASSWORD="$4"  # Optional: Password for encrypted archives

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
            7z e -p"$PASSWORD" "$ARCHIVE_PATH" -o"$OUTPUT" -y
        else
            # Extract without a password
            7z e "$ARCHIVE_PATH" -o"$OUTPUT" -y
        fi
    else       
        #extract with paths                        
        if [ -n "$PASSWORD" ]; then
            # If a password is provided, use it for extraction
            7z x -p"$PASSWORD" "$ARCHIVE_PATH" -o"$OUTPUT" -y
        else
            # Extract without a password
            7z x "$ARCHIVE_PATH" -o"$OUTPUT" -y
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


#Get the loaction the archive files 
select_archive() {
    #Get ONLY ONE file
    local FILE
    local ARCHIVE_MIME='^application/(zip|x-tar|x-gzip|x-bzip2|x-7z-compressed|x-rar-compressed|x-xz)$'

    FILE=$(zenity --file-selection \
                  --multiple \
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




main(){
    select_archive  #Get Archive location
    if [ $? -ne 0 ]; then
        echo "Error Selecting File"
        exit 1
    fi

    echo "Selected File $FILES"
    if [ -z "$FILES" ]; then
        echo "Selected File $FILES"
    fi
  
    zenity --notification --text="Extracting Game Archive" --title="Game Install"

    extract_archive "$FILES" "$ROMs_FOLDER/$CONF_FILE_NAME/" "x"
    if [ $? -ne 0 ]; then 
        #remove Game folder from ROMs/dox directory
        zenity --error --text="Error: Archive extraction failed \n$FILES"
        rm -f -r $ROMs_FOLDER/$CONF_FILE_NAME
        exit 1
    fi    
    zenity --notification --text="Extraction complete" --title="Game Install"

    #Download conf file from github
    download_file "$CONF_FILE_URL"  "$ROMs_FOLDER/$CONF_FILE_NAME" "$CONF_FILE_NAME"
    # Check if wget succeeded
    if [ $? -ne 0 ]; then
        echo "Failed to download: '$CONF_FILE_URL'"
        zenity --error --text="Error: Conf download failed \n$CONF_FILE_URL"
        rm -f -r $ROMs_FOLDER/$CONF_FILE_NAME
        exit 1
    fi

    touch "$ROMs_FOLDER/$CONF_FILE_NAME/noload.txt"


    zenity --notification --text="Game install complete" --title="Game Install"
}



main

exit