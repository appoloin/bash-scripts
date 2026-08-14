#!/bin/bash

#Game        : Tomb Raider I
#
#Source      : GOG EXE
#
#Runner      : Linux Port
#
#Description : This script will extract the an Archived ISO into ROMs/ports folder .
#              1: Get Game file
#              2: Create Game folder in ROMS/ports nameed $GME_NAME (ESDE needs this)
#              3: Extract Game files Archive 
#              4: Create sh file and noload file


#Constants
ROMs_FOLDER="$HOME/Games/ROMs/ports"
NAME="tomb-raider-i"
GAME_NAME="$NAME.sh"
TEMP_FOLDER="$ROMs_FOLDER/$GAME_NAME/temp"
ENGINE_URL="https://www.dropbox.com/scl/fi/5q363vgpk1ohupseqc5mw/TRX-1.10-Linux.zip?rlkey=cslj5cwi31fb6q0bmsc272y1x&st=rr2f8glh&dl=1"
ENGINE_NAME="TRX-1.10-Linux.zip"
ENGINE_EXE="TRX"
INNO_URL="https://www.dropbox.com/scl/fi/j0fpcie1r4afohmdjw2yb/innoextract-1.9.7z?rlkey=i0n1k54rr69n7ccosapvmmqbc&st=xqrri3av&dl=1"
INNO_ARCHIVE_NAME="innoextract-1.9.7z"
INNO_EXE="innoextract"
FILE_FILTER=""
CD_TOOLS_URL="https://www.dropbox.com/scl/fi/p0rpuh2wbillkzhs8xy62/iat?rlkey=6a59tblqocxbpudqxw4ed8hem&st=xsxdlr89&dl=1"
CD_TOOLS_EXE="iat"
MUSIC_URL="https://www.dropbox.com/scl/fi/vvnywthwrj3ohrdpypjxi/musicTR1.zip?rlkey=9j7smlx8r5rxkbefm3q8lmps8&st=a5vlapuh&dl=1"
MUSIC_ARCHIVE_NAME="musicTR1.zip"

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


    select_exe_installer  
    if [ $? -ne 0 ]; then
        echo "Error Selecting File"
        exit 1
    fi
   
    mkdir -p "$TEMP_FOLDER"

    EXE_PATH=$FILES

    #Download Engine and Extract
    zenity --notification --text="Downloading and installing engine" --title="Game Install"
    download_file "$ENGINE_URL"  "$TEMP_FOLDER" "$ENGINE_NAME"
    # Check if wget succeeded
    if [ $? -ne 0 ]; then
        echo "Failed to download: '$ENGINE_URL'"
        zenity --error --text="Error: Conf download failed \n$ENGINE_URL"
        rm -f -r $ROMs_FOLDER/$GAME_NAME
        exit 1
    fi

    extract_archive "$TEMP_FOLDER/$ENGINE_NAME" "$ROMs_FOLDER/$GAME_NAME" "x" "$FILE_FILTER"
    if [ $? -ne 0 ]; then 
        #remove Game folder
        rm -f -r "$ROMs_FOLDER/$GAME_NAME"
        exit 1
    fi


    zenity --notification --text="Downloading Tools" --title="Game Install" 
    #get innoextract archive from dropbox
    download_file "$INNO_URL" "$TEMP_FOLDER" "$INNO_ARCHIVE_NAME" 
    # Check if wget succeeded
    if [ $? -ne 0 ]; then
        rm -f -r "$ROMs_FOLDER/$GAME_NAME"
        exit 1
    fi
    #extract to TEMP  
    extract_archive "$TEMP_FOLDER/$INNO_ARCHIVE_NAME" "$TEMP_FOLDER" "x"
    if [ $? -ne 0 ]; then
        zenity --error --text="Error: Innoextract extract failed."
        rm -f -r "$ROMs_FOLDER/$GAME_NAME"
        exit 1
    fi

    download_file "$CD_TOOLS_URL" "$TEMP_FOLDER" "$CD_TOOLS_EXE" 
    if [ $? -ne 0 ]; then
        rm -f -r "$ROMs_FOLDER/$GAME_NAME"
        exit 1
    fi
    chmod +x "$TEMP_FOLDER/$CD_TOOLS_EXE"    

    download_file "$MUSIC_URL" "$TEMP_FOLDER" "$MUSIC_ARCHIVE_NAME" 


    zenity --notification --text="Running Innoextract" --title="Game Install"
    "$TEMP_FOLDER/$INNO_EXE" -d "$TEMP_FOLDER" "$EXE_PATH"
    if [ $? -ne 0 ]; then
        echo "Failed to extract EXE: '$EXE_PATH'"
        zenity --error --text="Error: Innoextract extraction of game exe failed \n'$EXE_PATH'."
        rm -f -r "$ROMs_FOLDER/$GAME_NAME"
        exit 1
    fi

    #find tool
    CD_EXE=$(find "$TEMP_FOLDER" -type f -iname "$CD_TOOLS_EXE" | head -n 1)
    # find cd BIN and convert
    CD_BIN=$(find "$TEMP_FOLDER" -type f -iname "*.gog" | head -n 1)
    echo "$CD_BIN"
    #Convert to iso
    cd "$TEMP_FOLDER"
    "$CD_EXE" -i "$CD_BIN" --iso
    CD_ISO=$(find "$TEMP_FOLDER" -type f -iname "*.iso" | head -n 1)
    #extract ISO
    mkdir -p $TEMP_FOLDER/game_cd
    extract_archive "$CD_ISO" "$TEMP_FOLDER/game_cd" "x"
    if [ $? -ne 0 ]; then
        zenity --error --text="Error: ISO extract failed."
        rm -f -r "$ROMs_FOLDER/$GAME_NAME"
        exit 1
    fi

    mkdir -p "$ROMs_FOLDER/$GAME_NAME/games/tr1/levels"
    find "$TEMP_FOLDER/game_cd/DATA" -mindepth 1 -maxdepth 1 -name "*"  -exec mv {} "$ROMs_FOLDER/$GAME_NAME/games/tr1/levels" \;
    mkdir -p "$ROMs_FOLDER/$GAME_NAME/games/tr1/fmv"
    find "$TEMP_FOLDER/game_cd/FMV"  -mindepth 1 -maxdepth 1 -name "*"  -exec mv {} "$ROMs_FOLDER/$GAME_NAME/games/tr1/fmv" \;

    zenity --notification --text="Extracting Music" --title="Game Install"
    mkdir -p "$TEMP_FOLDER/new_music"
    extract_archive "$TEMP_FOLDER/$MUSIC_ARCHIVE_NAME" "$TEMP_FOLDER/new_music" "x"
    find "$TEMP_FOLDER/new_music"  -mindepth 1 -maxdepth 1 -name "music"  -exec mv {} "$ROMs_FOLDER/$GAME_NAME/games/tr1" \;


    touch "$ROMs_FOLDER/$GAME_NAME/noload.txt"
    #Create ES_DE launch file with engine code
    echo -e "#!/bin/bash\n\n$ROMs_FOLDER/$GAME_NAME/$ENGINE_EXE --mod tr1" > "$ROMs_FOLDER/$GAME_NAME/$GAME_NAME"

    #Cleam up temp folder
    rm -f -r "$TEMP_FOLDER"
    
    zenity --notification --text="Game install complete" --title="Game Install"
}




main

exit