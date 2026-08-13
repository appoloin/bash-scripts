#!/bin/bash

#Game        : Return to astle Wolfenstein
#
#Source      : Archvie GOG 
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
NAME="return-to-castle-wolfenstein"
GAME_NAME="$NAME.sh"
TEMP_FOLDER="$ROMs_FOLDER/$GAME_NAME/temp"
INNO_URL="https://www.dropbox.com/scl/fi/j0fpcie1r4afohmdjw2yb/innoextract-1.9.7z?rlkey=i0n1k54rr69n7ccosapvmmqbc&st=xqrri3av&dl=1"
INNO_ARCHIVE_NAME="innoextract-1.9.7z"
INNO_EXE="innoextract"
ENGINE_NAME="com.github.iortcw.iortcw"
ENGINE_DATA="$HOME/.var/app/com.github.iortcw.iortcw/"
FILE_FILTER=""



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
    local FILE=""


    select_archive  #Get Archive location
    if [ $? -ne 0 ]; then
        echo "Error Selecting File"
        exit 1
    fi
   
    mkdir -p "$TEMP_FOLDER"

    extract_archive "$FILES" "$TEMP_FOLDER" "e"
    if [ $? -ne 0 ]; then 
        #remove Game folder
        rm -f -r "$ROMs_FOLDER/$GAME_NAME"
        exit 1
    fi

    EXE_PATH=$(find "$TEMP_FOLDER" -type f -iname "*.exe" | head -n 1)

    zenity --notification --text="Installing Engine" --title="Game Install"

    #install flatpak from flathub
    flatpak install --or-update --user flathub -y --noninteractive "$ENGINE_NAME"
    if [ $? -ne 0 ]; then
        zenity --error --text="Installing flatpak $ENGINE_NAME"
        exit 1
    fi

    #let engine access game folder
    flatpak override "$ENGINE_NAME" --user --filesystem="$ROMs_FOLDER/$GAME_NAME"


    zenity --notification --text="Downloading Innoextract" --title="Game Install" 
    #get innoextract archive from dropbox
    download_file "$INNO_URL" "$TEMP_FOLDER" "$INNO_ARCHIVE_NAME" 
    # Check if wget succeeded
    if [ $? -ne 0 ]; then
        rm -f -r "$ROMs_FOLDER/$GAME_NAME"
        exit 1
    fi

    #extract to GameFolder/temp  
    extract_archive "$TEMP_FOLDER/$INNO_ARCHIVE_NAME" "$TEMP_FOLDER" "x"
    if [ $? -ne 0 ]; then
        zenity --error --text="Error: Innoextract extract failed."
        rm -f -r "$ROMs_FOLDER/$GAME_NAME"
        exit 1
    fi


    zenity --notification --text="Running Innoextract" --title="Game Install"
    "$TEMP_FOLDER/$INNO_EXE" -d "$TEMP_FOLDER" "$EXE_PATH"
    if [ $? -ne 0 ]; then
        echo "Failed to extract EXE: '$EXE_PATH'"
        zenity --error --text="Error: Innoextract extraction of game exe failed \n'$EXE_PATH'."
        rm -f -r "$ROMs_FOLDER/$GAME_NAME"
        exit 1
    fi
    find "$TEMP_FOLDER/app/Main"  -exec mv {} "$ROMs_FOLDER/$GAME_NAME" \;


    # Link flatpak data folder to GAME_NAME, Engine can now see games 
    rm -Rf "$ENGINE_DATA/main"    #remove old game files 
    mkdir -p "$ENGINE_DATA"   #make sure there is folder to link with
    ln -s -f -n "$ROMs_FOLDER/$GAME_NAME/Main" "$ENGINE_DATA/main"   # Link the folders 

    touch "$ROMs_FOLDER/$GAME_NAME/noload.txt"

    #Create ES_DE launch file with engine code
    echo -e "#!/bin/bash\n\nflatpak run $ENGINE_NAME +set r_fullscreen 1" > "$ROMs_FOLDER/$GAME_NAME/$GAME_NAME"


    #Cleam up temp folder
    rm -f -r "$TEMP_FOLDER"
    find "$ROMs_FOLDER/$GAME_NAME" -mindepth 1 -maxdepth 1  -type d \( -iname app -o \
                                                                -iname commonappdata -o \
                                                                -iname *redist -o \
                                                                -iname scummvm -o \
                                                                -iname dosbox* -o \
                                                                -iname *support -o \
                                                                -iname tmp \) -exec rm -r {} \;
                                            
    find "$ROMs_FOLDER/$GAME_NAME" -type f \( -iname goggame* -o \
                                              -iname webcache.zip \) -exec rm {} \;

    zenity --notification --text="Game install complete" --title="Game Install"
}




main

exit