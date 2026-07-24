#!/bin/bash

#Game        : Grim Fandango
#
#Source      : EXODos
#
#Runner      : Scummvm
#
#Description : This script will extract the an Archived ISO into ROMs/scummvm folder .
#              1: Get Game file
#              2: Create Game folder in ROMS/scummvm nameed $GAME_NAME with the extention scummvm (ESDE needs this)
#              4: Extract Game files Archive the form ISO


#Constants
ROMs_FOLDER="$HOME/Games/ROMs/scummvm"
SCUMMVM_NAME="grim"
GAME_NAME="$SCUMMVM_NAME.scummvm"
TEMP_FOLDER="$ROMs_FOLDER/$GAME_NAME/temp"
UPDATE_URL="https://www.dropbox.com/scl/fi/b3ioo9folgtn5s7yqw40g/GrimFandangoUpd101.7z?rlkey=zkwhomsyeylmwle9x47nwzb6f&dl=1"
UPDATE_NAME="Update.7z"
FILE_FILTER="-ir!*.lab -ir!*.LAB"
          
#Global
FILES=""  #Game File Location
RADIO_OPTION=0 #ISO = 1;  Archive = 2


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
    #Get MORE than ONE file
    local FILE
    local ARCHIVE_MIME='^application/(iso-image|x-cd-image|x-iso9660-image)$'

 FILE=$(zenity --file-selection \
                  --title="Select Game Archive"  \
                  --width=800 \
                  --height=500 \
                  --filename="$HOME/Downloads" \
                  --file-filter="CD Image | *.iso")

    # Exit if user cancels
    if [ $? -ne 0 ]; then 
        return 1 
    fi
    
    FILES="$FILE"

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


main(){

    local EXE_PATH=""
    local FILE=""
    local ISOs=()

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

        # Convert the Zenity output into a Bash array
        IFS='|' read -ra TEMP_ISO <<< "$FILES"
        ISOs=($(printf "%s\n" "${TEMP_ISO[@]}" | sort))

        mkdir "$ROMs_FOLDER/$GAME_NAME"
        
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
            rm -f -r "$ROMs_FOLDER/$GAME_NAME"
            exit 1
        fi

        while IFS= read -r -d $'\0' file; do
            TEMP_ISO+=("$file")
        done < <(find "$TEMP_FOLDER" -type f -name "*.iso" -print0)
        ISOs=($(printf "%s\n" "${TEMP_ISO[@]}" | sort))
    fi    

    zenity --notification --text="Extracting files from iso" --title="Game Install"
    for item in "${ISOs[@]}"; do
        echo "Selected: $item"
        extract_archive "$item" "$ROMs_FOLDER/$GAME_NAME" "e" "$FILE_FILTER"
        if [ $? -ne 0 ]; then 
            #remove Game folder
            rm -f -r "$ROMs_FOLDER/$GAME_NAME"
            rm -f -r "$TEMP_FOLDER"
            exit 1
        fi
    done

    zenity --notification --text="Downloading update file" --title="Game Install"
    #Download UPDATE file from github
    download_file "$UPDATE_URL"  "$TEMP_FOLDER" "$UPDATE_NAME"
    # Check if wget succeeded
    if [ $? -ne 0 ]; then
        echo "Failed to download: '$UPDATE_URL'"
        zenity --error --text="Error: Conf download failed \n$UPDATE_URL"
        rm -f -r $ROMs_FOLDER/$GAME_NAME
        exit 1
    fi
    extract_archive "$TEMP_FOLDER/$UPDATE_NAME" "$ROMs_FOLDER/$GAME_NAME" "e" "" "password"
    if [ $? -ne 0 ]; then 
        #remove Game folder
        rm -f -r "$ROMs_FOLDER/$GAME_NAME"
        exit 1
    fi

    #Create ES_DE launch file with engine code
    echo "$SCUMMVM_NAME" > "$ROMs_FOLDER/$GAME_NAME/$GAME_NAME"

    #Cleam up temp folder
    if [ -d  "$TEMP_FOLDER" ]; then
        rm -f -r "$TEMP_FOLDER"
    fi
    zenity --notification --text="Game install complete" --title="Game Install"
}




main

exit