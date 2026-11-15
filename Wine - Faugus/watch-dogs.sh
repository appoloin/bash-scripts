#!/bin/bash

#Game        : Watch_Dogs
#
#Source      : Windows Installer
#
#Runner      : Faugus Launcher Wine
#
#Description : This script will install the game into a new prefix.
#              1: Get Game file
#              2: Run Winetrick
#              3: Run Installer using WIne
#              4: Update Faugus Library metadata


#Constants
GAME_NAME="Watch_Dogs"
GAME_ID="watch-dogs"
WINETRICKS="dotnet40"
FLATPAK_ID="io.github.Faugus.faugus-launcher"
LIBRARY="$HOME/.var/app/$FLATPAK_ID/config/games.json"
UMU_RUN="$HOME/.var/app/$FLATPAK_ID/data/faugus-launcher/umu-run"

export PROTONPATH="$HOME/.local/share/Steam/compatibilitytools.d/Proton-CachyOS Latest"
export WINEPREFIX="$HOME/Games/$GAME_ID"
export STORE="GOG"
export GAMEID=""

GAME_EXE_PATH="$WINEPREFIX/drive_c/Games/"


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



#GET Location of CD images iso, cue/bin
select_exe_installer() {
    # Use zenity to select files
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
    select_exe_installer  #Get Installer location
    if [ $? -ne 0 ]; then
        echo "Error Selecting File"
        exit 1
    fi
    INSTALLER="$FILES"

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