#!/bin/bash

#Game        : Starwars X-Wing  Allianc
#
#Source      : Archive/ GOG
#
#Runner      : Dreamm
#
#Description : This script will extract into ROMs/PC folder .
#              1: Get Game  Archive location
#              2: Create Game folder  in ROMS/PC add exe extenstion to folder name (ESDE needs this)
#              3: Extract Game Archive if used
#              4: Run Inno to extract GOG installer


#Constants
ROMs_FOLDER="$HOME/Games/ROMs/pc"
GAME_NAME="star-wars-x-wing-alliance.exe"
TEMP_FOLDER="temp"
INNO_URL="https://www.dropbox.com/scl/fi/j0fpcie1r4afohmdjw2yb/innoextract-1.9.7z?rlkey=i0n1k54rr69n7ccosapvmmqbc&st=xqrri3av&dl=1"
INNO_ARCHIVE_NAME="innoextract-1.9.7z"
INNO_EXE="innoextract"
RADIO_OPTION=0 #ISO = 1;  Archive = 2

#extract archive  
#"$1" Archive Path
#"S2" Output Path
#"S3" Extract with (x) or Without Path (e) 
#"S4" Password OPTIONAL
extract_archive() {
    local ARCHIVE_PATH="$1"
    local OUTPUT="$2"
    local EXTRACT_METHOD="$3"
    local PASSWORD="$4"  # Optional: Password for encrypted archives

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
            7z e -p"$PASSWORD" "$ARCHIVE_PATH" -o"$OUTPUT" -y
        else
            # Extract without a password
            7z e "$ARCHIVE_PATH" -o"$OUTPUT" -y
        fi
    else       
        #extract with paths                        
        if [ -n "$PASSWORD" ]; then
            # If a password is provided, use it for extraction
            7z x -p"$PASSWORD" "$ARCHIVE_PATH" -o"$OUTPUT" -y
        else
            # Extract without a password
            7z x "$ARCHIVE_PATH" -o"$OUTPUT" -y
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


#Get the loaction the archive files 
select_archive() {
    #Get ONLY ONE file
    local FILE
    local ARCHIVE_MIME='^application/(zip|x-tar|x-gzip|x-bzip2|x-7z-compressed|x-rar-compressed|x-xz)$'

 FILE=$(zenity --file-selection \
                  --title="Select Game Archive"  \
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





get_source_type () {
    # Show the radio dialog
    local SELECTED
    SELECTED=$(zenity --list \
                      --radiolist \
                      --title="Select Source Type" \
                      --text="Choose source of game files:" \
                      --column="Select" \
                      --column="Source" \
                      FALSE "GOG EXE Installer" \
                      FALSE "Archive" )
    

    # Check if user canceled
    if [ $? -ne 0 ]; then 
        return 1 
    fi

    case "$SELECTED" in
        "GOG EXE Installer")
            RADIO_OPTION=1
            ;;
        "Archive")
            RADIO_OPTION=2
            ;;
        *)
            echo "Unknown selection: $SELECTED"
            RADIO_OPTION=0
            return 1
            ;;
    esac

}


main(){

    local EXE_PATH=""

    get_source_type
    if [ $? -ne 0 ]; then
        echo "Error Selecting File"
        exit 1
    fi

    if [[ $RADIO_OPTION -le 0 ]]; then
        echo "Selected: $RADIO_OPTION"
        zenity --error --text="Error: Selction Unknown : $RADIO_OPTION"
        exit 1
    elif  [[ $RADIO_OPTION -eq 1 ]]; then #GOG Installer

        select_exe_installer  
        if [ $? -ne 0 ]; then
            echo "Error Selecting File"
            exit 1
        fi

        EXE_PATH=$FILES

        mkdir -p "$ROMs_FOLDER/$GAME_NAME/$TEMP_FOLDER"

    elif  [[ $RADIO_OPTION -eq 2 ]]; then #Archive

        select_archive  #Get Archive location
        if [ $? -ne 0 ]; then
            echo "Error Selecting File"
            exit 1
        fi

        mkdir -p "$ROMs_FOLDER/$GAME_NAME/$TEMP_FOLDER"

        zenity --notification --text="Extracting Game Archive" --title="Game Install"

        extract_archive "$FILES" "$ROMs_FOLDER/$GAME_NAME/$TEMP_FOLDER" "e"
        if [ $? -ne 0 ]; then 
            #remove Game folder
            rm -f -r "$ROMs_FOLDER/$GAME_NAME"
            exit 1
        fi
        
        EXE_PATH=$(find "$ROMs_FOLDER/$GAME_NAME/$TEMP_FOLDER" -maxdepth 1 -type f   -iname "*.exe")
        if [ -z "$EXE_PATH" ]; then
            echo "Path Not Found $EXE_PATH"
            zenity --error --text="Error: Game Installer EXE not found.)."
            rm -f -r "$ROMs_FOLDER/$GAME_NAME"
            exit 1
        fi

        zenity --notification --text="Extraction complete" --title="Game Install"

    fi


    zenity --notification --text="Downloading Innoextract" --title="Game Install"

    mkdir -p "$ROMs_FOLDER/$GAME_NAME/$TEMP_FOLDER"
   
    #get innoextract archive from dropbox
    download_file "$INNO_URL" "$ROMs_FOLDER/$GAME_NAME/$TEMP_FOLDER" "$INNO_ARCHIVE_NAME" 
    # Check if wget succeeded
    if [ $? -ne 0 ]; then
        rm -f -r "$ROMs_FOLDER/$GAME_NAME"
        exit 1
    fi

    #extract to ROMs/pc/Game folder/temp  
    extract_archive "$ROMs_FOLDER/$GAME_NAME/$TEMP_FOLDER/$INNO_ARCHIVE_NAME" "$ROMs_FOLDER/$GAME_NAME/$TEMP_FOLDER" "x"
    if [ $? -ne 0 ]; then
        zenity --error --text="Error: Innoextract extract failed."
        rm -f -r "$ROMs_FOLDER/$GAME_NAME"
        exit 1
    fi

    zenity --notification --text="Run Innoextract" --title="Game Install"
    #extracting GOG installer with Inno, taking only the app folder
    "$ROMs_FOLDER/$GAME_NAME/$TEMP_FOLDER/$INNO_EXE" -I app -d "$ROMs_FOLDER/$GAME_NAME" "$EXE_PATH"
    if [ $? -ne 0 ]; then
        echo "Failed to extract EXE: '$EXE_PATH'"
        zenity --error --text="Error: Innoextract extraction of game exe failed \n'$EXE_PATH'."
        rm -f -r "$ROMs_FOLDER/$GAME_NAME"
        exit 1
    fi
    #Move files/folders from app folder to main game folder
    find "$ROMs_FOLDER/$GAME_NAME/app" -mindepth 1 -maxdepth 1 -name "*"  -exec cp {} -r "$ROMs_FOLDER/$GAME_NAME" \;
    #delete app folder
    rm -f -r $ROMs_FOLDER/$GAME_NAME/app
    #dlete temp folder
    rm -f -r "$ROMs_FOLDER/$GAME_NAME/$TEMP_FOLDER"
    zenity --notification --text="Game install complete" --title="Game Install"
}




main

exit