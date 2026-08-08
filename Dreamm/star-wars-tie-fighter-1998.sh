#!/bin/bash
#Game        : STAR WARS - TIE Fighter
#
#Source      : Archiive
#
#Runner      : Dreamm
#
#Description : This script will extract the Archive into ROMs/PC folder .
#              1: Get Game file 
#              2: Create Game folder  in ROMS/pc add exe extenstion to folder name (ESDE needs this)
#              3: Extract Game Archive
#              4: Use Dream to install game


#Constants
ROMs_FOLDER="$HOME/Games/ROMs/pc"
GAME_NAME="lec-tie.exe"
TEMP_FOLDER="$ROMs_FOLDER/$GAME_NAME/temp"
DREAMM_PATH="$HOME/Applications/dreamm/dreamm"
DREAMM_CONF_PATH_1="$HOME/.local/share/Aaron Giles/DREAMM/install/lec-tie"
DREAMM_CONF_PATH="$DREAMM_CONF_PATH_1/pc-en-cd"
DREAMM_CONF_PATH_2="$DREAMM_CONF_PATH_1/pc-en-cd+joyfix"
UPGRADE_URL="https://www.dropbox.com/scl/fi/o25m7jss9fhqs9biib7vp/Tiecdjoy.exe?rlkey=zqq1hb30capoze50sb71ps5bd&st=e62o89zs&dl=1"
UPGRADE_NAME="Tiecdjoy.exe"

#Global
FILES=""  #Game File Location


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


    select_archive  #Get Archive location
    if [ $? -ne 0 ]; then
        echo "Error Selecting File"
        exit 1
    fi

    EXE_PATH="$FILES"

    mkdir -p "$TEMP_FOLDER"

 #   zenity --notification --text="Downloading & Installing Update" --title="Game Install"
    #Download conf file from github
 #   download_file "$UPGRADE_URL" "$TEMP_FOLDER" "$UPGRADE_NAME"
    # Check if wget succeeded
 #   if [ $? -ne 0 ]; then
 #       echo "Failed to download: '$UPGRADE_URL'"
 #       zenity --error --text="Error: Conf download failed \n$UPGRADE_URL"
 #       rm -f -r "$ROMs_FOLDER/$GAME_NAME"
 #       rm -f -r "$DREAMM_CONF_PATH_1"
 #       exit 1
 #   fi


    #Use Dreamm to install the Game
    zenity --notification --text="Dreamm is installing game" --title="Game Install"
    "$DREAMM_PATH" -autoinstall "$EXE_PATH"
    if [ $? -ne 0 ]; then 
        zenity --error --text="Dreamm failed to find game"
        #remove Game folder
        echo "Error Dreamm install"
        rm -f -r "$ROMs_FOLDER/$GAME_NAME"
        exit 1
    fi


    UPGRADE_PATH=$(find "$TEMP_FOLDER" -type f -iname "*.exe" | head -n 1)
    "$DREAMM_PATH" -upgrade "$DREAMM_CONF_PATH" "$UPGRADE_PATH"

    #move game install folder to es-de pc folder
    find "$DREAMM_CONF_PATH"  -mindepth 1 -maxdepth 1 -name "*"  -exec mv {} "$ROMs_FOLDER/$GAME_NAME" \;
    if [ $? -ne 0 ]; then 
        zenity --error --text="Dreamm failed to install game"
        #remove Game folde
        echo "Error moving game files"
        rm -f -r "$ROMs_FOLDER/$GAME_NAME"
        rm -f -r "$DREAMM_CONF_PATH"
       # rm -f -r "$DREAMM_CONF_PATH_2"
        exit 1
    fi
    #rm -f -r "$DREAMM_CONF_PATH_2"
    rm -f -r "$DREAMM_CONF_PATH"
    rm -f -r "$TEMP_FOLDER"
    zenity --notification --text="Game install complete" --title="Game Install"
}




main

exit