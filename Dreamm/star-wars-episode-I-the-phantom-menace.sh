#!/bin/bash
#Game        : Star Wars - Episode 1 - The Phantom Menice
#
#Source      : Image
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
GAME_NAME="lec-phantom.exe"
TEMP_FOLDER="$ROMs_FOLDER/$GAME_NAME/temp"
DREAMM_PATH="$HOME/Applications/dreamm/dreamm"
DREAMM_CONF_PATH_1="$HOME/.local/share/Aaron Giles/DREAMM/install/lec-phantom"
DREAMM_CONF_PATH="$DREAMM_CONF_PATH_1/pc-1.0-en"

#Global
FILES=""  #Game File Location


select_image() {
    #Get ONLY ONE file
    local FILE

    FILE=$(zenity --file-selection \
                  --title="Select Game Archive" \
                  --width=800 \
                  --height=500 \
                  --filename="$HOME/Downloads" \
                  --file-filter="Disc Image | *.iso  *.ISO")

    # Exit if user cancels
    if [ $? -ne 0 ]; then 
        return 1 
    fi
    
    # Return the selected archive
    FILES="$FILE"
    return 0
}






main(){

    local EXE_PATH=""

    select_image  #Get disk image location
    if [ $? -ne 0 ]; then
        echo "Error Selecting File"
        exit 1
    fi

    EXE_PATH="$FILES"

    mkdir -p "$ROMs_FOLDER/$GAME_NAME"

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

    #move game install folder to es-de pc folder
    find "$DREAMM_CONF_PATH"  -mindepth 1 -maxdepth 1 -name "*"  -exec mv {} "$ROMs_FOLDER/$GAME_NAME" \;
    if [ $? -ne 0 ]; then 
        zenity --error --text="Dreamm failed to install game"
        #remove Game folde
        echo "Error moving game files"
        rm -f -r "$ROMs_FOLDER/$GAME_NAME"
        rm -f -r "$DREAMM_CONF_PATH_1"
        exit 1
    fi
    rm -f -r "$DREAMM_CONF_PATH_1"

    zenity --notification --text="Game install complete" --title="Game Install"
}




main

exit