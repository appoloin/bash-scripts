#!/bin/bash

#Game        : Forza Horzion 2,3,FM5,FM6 (Azimuth)
#
#Source      : Engine
#
#Runner      : Faugus Launcher Wine
#
#Description : This script will install the game into a new prefix.
#              1: Download Engine
#              2: Create prefix
#              3: Extract engine into prefix
#              4: Create ES_DE shortcut

#Constants
GAME_NAME="forza-horizon-azimuth"
GAME_ID="forza-horizon-azimuth"
WINETRICKS=""
FLATPAK_ID="io.github.Faugus.faugus-launcher"
LIBRARY="$HOME/.var/app/$FLATPAK_ID/config/games.json"
UMU_RUN="$HOME/.var/app/$FLATPAK_ID/data/faugus-launcher/umu-run"
ENGINE_URL="https://www.dropbox.com/scl/fi/r8in6boy8cubvq67smbkg/azimuth-windows-1-0-2.zip?rlkey=q0sjth0ibrhia1gt1jbn5r9lq&st=76ciu2bo&dl=1"
ENGINE_NAME="azimuth-windows.zip"
ENGINE_EXE="azimuth.exe"
ROMs_FOLDER="$HOME/Games/ROMs/ports"
SHORTCUT_FILE_NAME="$GAME_NAME.sh"


export PROTONPATH="$HOME/.local/share/Steam/compatibilitytools.d/Proton-CachyOS Latest"
export WINEPREFIX="$HOME/Games/$GAME_ID"
export STORE="GOG"
export GAMEID=""

GAME_EXE_PATH="$WINEPREFIX/drive_c/Games"


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

    #Download Engine and Extract
    mkdir -p "$GAME_EXE_PATH"
    zenity --notification --text="Downloading and installing engine" --title="Game Install"
    download_file "$ENGINE_URL"  "$GAME_EXE_PATH" "$ENGINE_NAME"
    # Check if wget succeeded
    if [ $? -ne 0 ]; then
        echo "Failed to download: '$ENGINE_URL'"
        zenity --error --text="Error: Conf download failed \n$ENGINE_URL"
        rm -f -r $ROMs_FOLDER/$GAME_NAME
        exit 1
    fi

    extract_archive "$GAME_EXE_PATH/$ENGINE_NAME" "$GAME_EXE_PATH" "x" "$FILE_FILTER"
    if [ $? -ne 0 ]; then 
        #remove Game folder
        zenity --error --text="Error: Archive extraction failed \n$FILES"
        exit 1
    fi



    #Create ES_DE launch file with engine code
    echo -e "#!/bin/bash\n\n$UMU_RUN $GAME_EXE_PATH/$ENGINE_EXE" > "$ROMs_FOLDER/$SHORTCUT_FILE_NAME"

    zenity --notification --text="Game install complete" --title="Game Install"
}




main

exit