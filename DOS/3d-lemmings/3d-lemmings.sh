#!/bin/bash

#Game        : 3D lemmings
#
#Source      : Archive / CD image
#
#Runner      : DosBox
#
#Description : This script will extract the GOG installer into ROMs/PC folder .
#              1: Get Game file(s) either an Archived  or CD image 
#              2: Create Game folder  in ROMS/dos add conf extenstion to folder name (ESDE needs this)
#              3: Extract Game Archive if used


#Constants
ROMs_FOLDER="$HOME/Games/ROMs/dos"
GAME_NAME="3d-lemmings.conf"
GAME_DRIVE_FOLDER="drives/d"
CONF_FILE_URL="https://raw.githubusercontent.com/appoloin/bash-scripts/refs/heads/main/Win311/titanic-adventure-out-of-time/titanic-adventure-out-of-time.conf"
CONF_FILE_NAME="titanic-adventure-out-of-time.conf"
TEMP_FOLDER="temp"
FILE_FILTER="-ir!*.cue -ir!*.bin"


#Global
FILES=""  #Game File Location
RADIO_OPTION=0 #CD Image = 1;  Archive = 2


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


#GET Location of CD images iso, cue/bin
select_cd_image_files() {
    # Use zenity to select files
    local files
    files=$(zenity --file-selection \
                   --multiple \
                   --width=800 \
                   --height=500 \
                   --separator=$'\n' \
                   --filename="$HOME/Downloads" \
                   --title="Select CD image files" \
                   --file-filter="CD IMAGE | *.iso *.cue *.bin *.mp3" )

    # Exit if user cancels
    if [ $? -ne 0 ]; then
        return 1
    fi

    # Return the selected files
    FILES="${files}"
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
                      FALSE "CD Image" \
                      FALSE "Archive" )
    

    # Check if user canceled
    if [ $? -ne 0 ]; then 
        return 1 
    fi

    case "$SELECTED" in
        "CD Image")
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


main(){
    get_source_type
    if [ $? -ne 0 ]; then
        echo "Error Selecting File"
        exit 1
    fi

    if [[ $RADIO_OPTION -le 0 ]]; then
        echo "Selected: $RADIO_OPTION"
        zenity --error --text="Error: Selction Unknown : $RADIO_OPTION"
        exit 1
    elif  [[ $RADIO_OPTION -eq 1 ]]; then #CD IMAGE

        select_cd_image_files   #one or more files returned
        if [ $? -ne 0 ]; then
            echo "Error Selecting File"
            exit 1
        fi

        #Create cdrom folder in Doxbox bottle
        mkdir -p "$ROMs_FOLDER/$GAME_NAME/$GAME_DRIVE_FOLDER"

        zenity --notification --text="Copying Files to ROMs folder" --title="Game Install"

        while IFS= read -r FILE; do
            # Skip empty lines (if any)
            if [[ -z "$FILE" ]]; then
                continue
            fi

            echo "Processing: $FILE"
            #copy iso to ROMs folder
            cp "$FILE" "$ROMs_FOLDER/$GAME_NAME/$GAME_DRIVE_FOLDER"
            if [ $? -ne 0 ]; then
                echo "COPY Failed. Exiting.\n  $FILE to  $ROMs_FOLDER/$GAME_NAME/$GAME_DRIVE_FOLDER"
                zenity --error --text="COPY failed: \n   $FILE \n to  \n $ROMs_FOLDER/$GAME_NAME/$GAME_DRIVE_FOLDER"
                #remove Game folder from ROMs/window3x directory
                rm -f -r $ROMs_FOLDER/$GAME_NAME
                exit 1
            fi
        done <<< "$FILES"

        zenity --notification --text="Copy Complete" --title="Game Instal"


    elif  [[ $RADIO_OPTION -eq 2 ]]; then #Archive

        select_archive  #Get Archive location
        if [ $? -ne 0 ]; then
            echo "Error Selecting File"
            exit 1
        fi

        echo "Selected File $FILES"
        if [ -z "$FILES" ]; then
            echo "Selected File $FILES"
        fi

        #create game bottle
        mkdir -p $ROMs_FOLDER/$GAME_NAME
        
        zenity --notification --text="Extracting Game Archive" --title="Game Install"

        extract_archive "$FILES" "$ROMs_FOLDER/$GAME_NAME/$GAME_DRIVE_FOLDER" "e" "$ILE_FILTER"
        if [ $? -ne 0 ]; then 
            #remove Game folder from ROMs/dox directory
            zenity --error --text="Error: Archive extraction failed \n$FILES"
            rm -f -r $ROMs_FOLDER/$GAME_NAME
            exit 1
        fi
        
        zenity --notification --text="Extraction complete" --title="Game Install"

    fi

    #Download conf file from github
    download_file "$CONF_FILE_URL"  "$ROMs_FOLDER/$GAME_NAME" "$CONF_FILE_NAME"
    # Check if wget succeeded
    if [ $? -ne 0 ]; then
        echo "Failed to download: '$CONF_FILE'"
        zenity --error --text="Error: Conf download failed \n$CONF_FILE"
        rm -f -r $ROMs_FOLDER/$GAME_NAME
        exit 1
    fi

    touch "$ROMs_FOLDER/$GAME_NAME/drives/noload.txt"

    #run Game install
    flatpak run io.github.dosbox-staging -conf "$ROMs_FOLDER/$GAME_NAME/$CONF_FILE_NAME"

    zenity --notification --text="Game install complete" --title="Game Install"
}




main

exit