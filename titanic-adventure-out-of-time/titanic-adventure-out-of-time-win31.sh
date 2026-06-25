#!/bin/bash

ROMs_FOLDER="$HOME/Games/ROMs/window3x"
GAME_NAME="titianic_adventure_out_of_time.conf"
WIN311_URL="https://www.dropbox.com/scl/fi/2b1x6cj30tdqq2me9kzv6/Win311.7z?rlkey=0xvdjybfq2242cry48huoyzsc&dl=0" 


download_and_install_windows() {
    #create game bottle
    mkdir -p $ROMs_FOLDER/$GAME_NAME

    #get Win311 archive from dropbox
    wget -P "$ROMs_FOLDER/$GAME_NAME"  -O "$ROMs_FOLDER/$GAME_NAME/Win311.7z" "$WIN311_URL" 
    # Check if wget succeeded
    if [ $? -ne 0 ]; then
        echo "Failed to download: '$WIN311_URL'"
        zenity --error --text="Failed to download: Win311.7z \nCheck the URL or your internet connection."
        rm -f -r $ROMs_FOLDER/$GAME_NAME
        exit 1
    fi

    #extract to ROMs/Windows3x/Game folder  
    7z x "$ROMs_FOLDER/$GAME_NAME/Win311.7z" -o"$ROMs_FOLDER/$GAME_NAME" -y
    if [ $? -ne 0 ]; then
        echo "Archive not found: $ROMs_FOLDER/$GAME_NAME/Win311.7z"
        zenity --error --text="Archive not found: \n $ROMs_FOLDER/$GAME_NAME/Win311.7z"
        rm -f -r $ROMs_FOLDER/$GAME_NAME
        exit 1
    fi

    #deleted downloaded zip
    rm -f "$ROMs_FOLDER/$GAME_NAME/Win311.7z"
}




#Get Game file
FILE=$(zenity --file-selection \
            --title="Select Game Archive" \
            --width=800 \
            --height=500 \
            --filename="$HOME/Downloads" \
            --file-filter="Archive | *.zip *.7z" \
            --file-filter="Disc Image | *.iso" )

if [ -z "$FILE" ]; then
    echo "No file selected."
    exit 1
fi


#Check for ISO or Zip
if file --mime-type -b "$FILE" | grep -qE 'application/(zip|x-tar|x-gzip|x-bzip2|x-7z-compressed|x-rar-compressed|x-xz)'; then
    #download win3 and install 
    if $(download_and_install_windows) ; then
        echo "Download failed. Exiting."
        exit 1
    fi
  
    #extract archive 
    7z e $FILE -o "$ROMs_FOLDER/$GAME_NAME/drives/d" -y
    if [$? -ne 0 ]; then
        echo "Extract failed. Exiting.\n  $FILE"
        zenity --error --text="Archive not found: \n $FILE"
        #remove Game folder from ROMs/window3x directory
        rm $ROMs_FOLDER/$GAME_NAME
        exit 1
    fi

elif file --mime-type -b "$FILE" | grep -q "application/x-iso9660-image"; then
    #download win3 and install
    if $(download_and_install_windows) ; then
        echo "Download failed. Exiting."
        exit 1
    fi

    #copy iso to ROMs folder
    mkdir -p $ROMs_FOLDER/$GAME_NAME/drives/d
    if [$? -ne 0 ]; then
        echo "MKDIR failed. Exiting.\n   $ROMs_FOLDER/$GAME_NAME/drives/d"
        zenity --error --text="MKDIR failed: \n  $ROMs_FOLDER/$GAME_NAME/drives/d"
        #remove Game folder from ROMs/window3x directory
        rm $ROMs_FOLDER/$GAME_NAME
        exit 1
    fi

    cp $FILE $ROMs_FOLDER/$GAME_NAME/drives/d
    if [$? -ne 0 ]; then
        echo "COPY Failed. Exiting.\n  $FILE to  $ROMs_FOLDER/$GAME_NAME/drives/d"
        zenity --error --text="COPY failed: \n   $FILE \n to  \n $ROMs_FOLDER/$GAME_NAME/drives/d"
        #remove Game folder from ROMs/window3x directory
        rm $ROMs_FOLDER/$GAME_NAME
        exit 1
    fi

else
    zenity --info --text="The selected file is unknown."
    exit 1
fi



#Download conf file from github



#run Game install
flatpak run io.github.dosbox-staging -conf "$ROMs_FOLDER/$GAME_NAME/titanic-adventure-out-of-time.conf"



