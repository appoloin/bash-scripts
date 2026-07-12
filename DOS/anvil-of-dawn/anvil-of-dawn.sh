#!/bin/bash

#Game        : Anvil of Dawn
#
#Source      : GOG installer
#
#Runner      : DosBox
#
#Description : This script will extract the GOG installer into ROMs/dos folder .
#              1: Get Game file
#              2: Create Game folder in ROMS/dos add conf extention to folder name (ESDE needs this)
#              3: Extract Game 
#              4: Downlad conf file from github

#Constants
ROMs_FOLDER="$HOME/Games/ROMs/dos"
CONF_FILE_URL="https://raw.githubusercontent.com/appoloin/bash-scripts/refs/heads/main/DOS/anvil-of-dawn/anvil-of-dawn.conf"
CONF_FILE_NAME="anvil-of-dawn.conf"
GUS_URL="https://www.dropbox.com/scl/fi/4hq9icbbe77uxhagveln8/ULTRASND.7z?rlkey=wadiyloc8ocarklbiuwow9fav&dl=1"
GUS_NAME="GUS_external_files.zip"
GUS_FOLDER="ULTRASND"
INNO_URL="https://www.dropbox.com/scl/fi/j0fpcie1r4afohmdjw2yb/innoextract-1.9.7z?rlkey=i0n1k54rr69n7ccosapvmmqbc&st=xqrri3av&dl=1"
INNO_ARCHIVE_NAME="innoextract-1.9.7z"
INNO_EXE="innoextract"
TEMP_FOLDER="$HOME/Games/ROMs/dos/anvil-of-dawn.conf/temp"
#GAME_FOLDER="anvil"

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

    local EXE_PATH=""
    zenity --notification --text="Installing Game" --title="Game Install"

    select_exe_installer  
    if [ $? -ne 0 ]; then
        echo "Error Selecting File"
        exit 1
    fi
    EXE_PATH="$FILES"

    mkdir -p "$TEMP_FOLDER"
   
    zenity --notification --text="Downloading GUS Drivers" --title="Game Install"

    #get GUS
    download_file "$GUS_URL" "$TEMP_FOLDER" "$GUS_NAME" 
    # Check if wget succeeded
    if [ $? -ne 0 ]; then
        rm -f -r "$ROMs_FOLDER/$CONF_FILE_NAME"
        exit 1
    fi
    #extraact GUS
    extract_archive "$TEMP_FOLDER/$GUS_NAME" "$ROMs_FOLDER/$CONF_FILE_NAME/" "x"
    if [ $? -ne 0 ]; then
        zenity --error --text="Error: GUS extract failed."
        rm -f -r "$ROMs_FOLDER/$CONF_FILE_NAME"
        exit 1
    fi

    zenity --notification --text="Downloading Innoextract" --title="Game Install"

    #get innoextract archive from dropbox
    download_file "$INNO_URL" "$TEMP_FOLDER" "$INNO_ARCHIVE_NAME" 
    # Check if wget succeeded
    if [ $? -ne 0 ]; then
        rm -f -r "$ROMs_FOLDER/$CONF_FILE_NAME"
        exit 1
    fi
    #extract to ROMs/pc/Game folder/temp  
    extract_archive "$TEMP_FOLDER/$INNO_ARCHIVE_NAME" "$TEMP_FOLDER" "x"
    if [ $? -ne 0 ]; then
        zenity --error --text="Error: Innoextract extract failed."
        rm -f -r "$ROMs_FOLDER/$CONF_FILE_NAME"
        exit 1
    fi


    zenity --notification --text="Running Innoextract" --title="Game Install"
    #extracting GOG installer with Inno
    "$TEMP_FOLDER/$INNO_EXE" -I app -d "$TEMP_FOLDER" "$EXE_PATH"
    if [ $? -ne 0 ]; then
        echo "Failed to extract EXE: '$EXE_PATH'"
        zenity --error --text="Error: Innoextract extraction of game exe failed \n'$EXE_PATH'."
        rm -f -r "$ROMs_FOLDER/$GAME_NAME"
        exit 1
    fi


    #copy files from temp to game folder "anvil"
   # mkdir -p "$ROMs_FOLDER/$CONF_FILE_NAME/$GAME_FOLDER" 
    #Move files/folders from app folder to main game folder
    find "$TEMP_FOLDER/app" -mindepth 1 -maxdepth 1 -name "*"  -exec cp {} -r "$ROMs_FOLDER/$CONF_FILE_NAME" \;


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

    #Clean up
    rm -f -r "$TEMP_FOLDER"
    find "$ROMs_FOLDER/$CONF_FILE_NAME" -maxdepth 1  -type d \( -iname app -o \
                                                                -iname commonappdata -o \
                                                                -iname *redist -o \
                                                                -iname scummvm -o \
                                                                -iname dosbox -o \
                                                                -iname dosbox_windows -o \
                                                                -iname *support -o \
                                                                -iname tmp \) -exec rm -r {} \;
                                            
    find "$ROMs_FOLDER/$CONF_FILE_NAME" -type f \( -iname "goggame*"-o \
                                                   -iname "webcache.zip" \) -exec rm {} \;

    zenity --notification --text="Game install complete" --title="Game Install"
}




main

exit