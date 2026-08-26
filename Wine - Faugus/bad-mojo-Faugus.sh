#!/bin/bash

#Game        : Bad Mojo
#
#Source      : GOG Installer
#
#Runner      : Faugus Launcher Wine
#
#Description : This script will install the game into a new prefix and then register the game will Faugus Launcher .
#              1: Get Game file
#              2: Run Winetrick
#              3: Run Installer using WIne
#              4: Update Faugus Library metadata


#Constants
GAME_NAME="Bad Mojo"
GAME_ID="bad_mojo"
WINEPREFIX="$HOME/Games/$GAME_ID"
GAME_EXE_PATH="$WINEPREFIX/drive_c/GOG Games/Bad Mojo/Launch Bad Mojo.lnk"
WINETRICKS=""
FLATPAK_ID="io.github.Faugus.faugus-launcher"
LIBRARY="$HOME/.var/app/$FLATPAK_ID/config/games.json"
UMU_RUN="$HOME/.var/app/$FLATPAK_ID/data/faugus-launcher/umu-run"

export PROTONPATH="$HOME/.local/share/Steam/compatibilitytools.d/Proton-CachyOS Latest"
export WINEPREFIX="$HOME/Games/$GAME_ID"
export STORE="GOG"
export GAMEID=""


#Global
FILES=""  #Game File Location


select_exe_installer() {
    local files
    files=$(zenity --file-selection \
                   --width=800 \
                   --height=500 \
                   --filename="$HOME/Downloads" \
                   --title="Select GOG EXE Installer" \
                   --file-filter="GOG Installer | *.exe *.EXE" )

    # Exit if user cancels
    if [ $? -ne 0 ]; then
        return 1
    fi

    # Return the selected files
    FILES="$files"
}





main(){

    zenity --notification --text="Installing Game" --title="Game Install"

    # Check for Faugus Flatpak
    if ! flatpak info "$FLATPAK_ID" &> /dev/null; then
        zenity --notification --text="Error Faugus Launcher (Flatpak) not found." --title="Game Install"
        echo "Flatpak Faugus Launcher not found"
        exit 1
    fi


    select_exe_installer  #Get Installer location
    if [ $? -ne 0 ]; then
        echo "Error Selecting File"
        exit 1
    fi
    INSTALLER="$FILES"
  

    zenity --notification --text="Running Wine & Winetricks" --title="Game Install"
    #Create Prefix
    "$UMU_RUN" ""

    # Run winetricks 
    if [ -n  "$WINETRICKS" ]; then
        "$UMU_RUN" winetricks "$WINETRICKS"
        if [ $? -ne 0 ]; then
            echo "Error runnung installer"
            zenity --notification --text="Error install installing winetricks" --title="Game Install"
            exit 1
        fi
    fi


    #Run installer
    "$UMU_RUN" "$INSTALLER"
    if [ $? -ne 0 ]; then
        echo "Error runnung installer"
        zenity --notification --text="Error Running installer" --title="Game Install"
        exit 1
    fi


    zenity --notification --text="Game install complete" --title="Game Install"
}




main

exit