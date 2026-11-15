#!/bin/bash

#Game        : Colin Mcrae Rally 2.0
#
#Source      : Windows Installer
#
#Runner      : Linux Port
#
#Description : 
#              1: Create Game folder in ROMS/ports nameed $GME_NAME (ESDE needs this)
#              2: Run installer using WINE
#              3: Get Engine and Install
#              4: Create sh file and noload file


#Constants
ROMs_FOLDER="$HOME/Games/ROMs/ports"
NAME="colin-mcrae-rally-20"
GAME_ID="$NAME"
GAME_NAME="$NAME.sh"
GAME_PATH="$ROMs_FOLDER/$GAME_ID/drive_c/Program Files (x86)/MagiPacks/Colin McRae Rally 2/"
TEMP_FOLDER="$ROMs_FOLDER/$GAME_NAME/temp"
ENGINE_URL="https://www.dropbox.com/scl/fi/fcp3h9efxxmr3geo9xf4n/OpenCMR2-1-9-Linux-x86_64.tar.gz?rlkey=2xid1wkyxr8nkzntpkh882q4w&st=5h21j6qd&dl=1"
ENGINE_NAME="OpenCMR2-1-9-Linux-x86_64.tar.gz"
ENGINE_NAME2="OpenCMR2-Linux-x86_64.tar"
ENGINE_EXE="opencmr2"
FILE_FILTER=""
WINETRICKS=""
FLATPAK_ID="io.github.Faugus.faugus-launcher"
UMU_RUN="$HOME/.var/app/$FLATPAK_ID/data/faugus-launcher/umu-run"

export PROTONPATH="$HOME/.local/share/Steam/compatibilitytools.d/Proton-CachyOS Latest"
export WINEPREFIX="$ROMs_FOLDER/$GAME_NAME/prefix"
export STORE="GOG"
export GAMEID=""





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


    mkdir -p "$TEMP_FOLDER"

    EXE_PATH=$FILES
   
    zenity --notification --text="Installing Engine" --title="Game Install"

    #Download Engine and Extract
    zenity --notification --text="Downloading and installing engine" --title="Game Install"
    download_file "$ENGINE_URL"  "$TEMP_FOLDER" "$ENGINE_NAME"
    # Check if wget succeeded
    if [ $? -ne 0 ]; then
        echo "Failed to download: '$ENGINE_URL'"
        zenity --error --text="Error: Download failed \n$ENGINE_URL"
        rm -f -r $ROMs_FOLDER/$GAME_NAME
        exit 1
    fi

    extract_archive "$TEMP_FOLDER/$ENGINE_NAME" "$TEMP_FOLDER" "e" "$FILE_FILTER"
    if [ $? -ne 0 ]; then 
        #remove Game folder
        exit 1
    fi
    extract_archive "$TEMP_FOLDER/$ENGINE_NAME2" "$ROMs_FOLDER/$GAME_NAME" "e" "$FILE_FILTER"
    if [ $? -ne 0 ]; then 
        #remove Game folder
        exit 1
    fi
    chmod +x "$ROMs_FOLDER/$GAME_NAME/$ENGINE_NAME"    

    #Move Game files  
    mkdir -p "$ROMs_FOLDER/$GAME_NAME/$GAME_ID" 
    find "$WINEPREFIX/drive_c/Program Files (x86)/MagiPacks/Colin McRae Rally 2"  -mindepth 1 -maxdepth 1 -name "*"  -exec mv {} "$ROMs_FOLDER/$GAME_NAME/$GAME_ID" \;

    touch "$ROMs_FOLDER/$GAME_NAME/noload.txt"

    #Create ES_DE launch file with engine code
    echo -e "#!/bin/bash\n\n $ROMs_FOLDER/$GAME_NAME/$ENGINE_EXE" > "$ROMs_FOLDER/$GAME_NAME/$GAME_NAME"


    #Cleam up temp folder
    rm -f -r "$TEMP_FOLDER"
    rm -f -r "$WINEPREFIX"

    zenity --notification --text="Game install complete" --title="Game Install"
}




main

exit