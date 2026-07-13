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
TEMP_FOLDER="$WINEPREFIX/temp"
FLATPAK_ID="io.github.Faugus.faugus-launcher"
LIBRARY="$HOME/.var/app/$FLATPAK_ID/config/games.json"
JQ_URL="https://www.dropbox.com/scl/fi/ar8imjh9n0pur72psqet9/jq-linux-amd64?rlkey=v5ila69aijosozjvgj5jdb4ue&dl=1"
JQ_EXE="jq-linux-amd64"
JQ_PATH="$TEMP_FOLDER/$JQ_EXE"

NEW_ENTRY='{
    "gameid": "'"$GAME_ID"'",
    "title": "'"$GAME_NAME"'",
    "path": "'"$GAME_EXE_PATH"'",
    "prefix": "'"$WINEPREFIX"'",
    "launch_arguments": "",
    "game_arguments": "",
    "mangohud": "",
    "gamemode": "",
    "disable_hidraw": "",
    "protonfix": "",
    "runner": "",
    "addapp_checkbox": "",
    "addapp": "",
    "addapp_bat": "",
    "addapp_delay": "",
    "addapp_first": false,
    "banner": "",
    "lossless_enabled": false,
    "lossless_multiplier": 1,
    "lossless_flow": 100,
    "lossless_performance": false,
    "lossless_hdr": false,
    "lossless_present": false,
    "playtime": 0,
    "hidden": false,
    "prevent_sleep": "",
    "category": "Game",
    "icon": ""
}'


#Global
FILES=""  #Game File Location


  
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
  
    zenity --notification --text="Downloading help file JQ" --title="Game Install"

    #get JQ 
    mkdir -p "$TEMP_FOLDER"
    download_file "$JQ_URL" "$TEMP_FOLDER" "$JQ_EXE" 
    # Check if wget succeeded
    if [ $? -ne 0 ]; then
        rm -f -r "$WINEPREFIX"
        exit 1
    fi
    chmod +x $JQ_PATH


    zenity --notification --text="Running Wine & Winetricks" --title="Game Install"
    # Run winetricks 
    if [ -n  "$WINETRICKS" ]; then
        flatpak run --env=WINEPREFIX="$WINEPREFIX" \
                    --command=winetricks "$FLATPAK_ID" \
                    "$WINETRICKS"
    fi

    flatpak run --env=WINEPREFIX="$WINEPREFIX" \
                --command=wine "$FLATPAK_ID" \
                "$INSTALLER"
    if [ $? -ne 0 ]; then
        echo "Error runnung installer"
        zenity --notification --text="Error Running installer" --title="Game Install"
        exit 1
    fi

    zenity --notification --text="Updating Faugus Libaray" --title="Game Install"

    # Append  new entry to the game.json array
    $JQ_PATH --argjson new_entry "$NEW_ENTRY" '. += [$new_entry]' "$LIBRARY" > tmp.json && mv tmp.json "$LIBRARY"
    if [ $? -ne 0 ]; then
        echo "Error updating metadata"
        zenity --notification --text="Error updating Faugus metadata. To add game to Library use Faugus GUI" --title="Game Install"
    fi

    #clean up
    rm -f -r "$TEMP_FOLDER"

    zenity --notification --text="Game install complete" --title="Game Install"
}




main

exit