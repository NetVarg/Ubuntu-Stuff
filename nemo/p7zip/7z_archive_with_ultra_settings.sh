#!/bin/bash
#
# The prerequisite is that 'p7zip-full' is installed.
# Adds all files or directories to archive archive.7z using "ultra settings".

# Extract the first file or directory name from the input string
# used as default archive name.
# With data and header archive encryption on (optional).

archName=$(basename -- "$1")
# Get current folder.
dir=$(dirname "$1")

usr_dir=$(zenity --file-selection \
    --title="Choose a directory (Cancel=No 7z compression)" \
    --file-filter=""*" "Desktop"" --directory --filename=$dir)

if [ $? = 0 ]; then
    usr_file=$(zenity --entry --width=600 \
        --title="Archive name (Cancel=No 7z compression)" \
        --text="Use the predefined filename or modify it" \
        --entry-text="${usr_dir}/${archName}.7z")

    if [ $? = 0 ]; then

        pwd=$(zenity --entry \
            --title="Enter a password OR cancel = no password" \
            --text="Password (optional)")

        if [ $? != 0 ]; then
            # Archive without password.
            # Adds all files or directories to archive using "ultra settings".
            message=$({ $(7z a -t7z -m0=lzma -mx=9 -mfb=64 -md=32m -ms=on \
                "${usr_file}" "$@" 2>&1 | 
                tee /dev/fd/3 |
            zenity --progress \
                --title="7Zip has started." \
                --text="7-Zip is running, please wait..." \
                --pulsate --auto-close --no-cancel); } 3>&1)
        else
            # With  data  and header archive encryption on.
            # he=[off|on] Enables or disables archive header encryption.
            # Adds all files or directories to archive using "ultra settings".
            message=$({ $(7z a -mhe=on -p$pwd -t7z -m0=lzma -mx=9 -mfb=64 -md=32m -ms=on \
                "${usr_file}" "$@" 2>&1 | 
                tee /dev/fd/3 |
            zenity --progress \
                --title="7Zip has started - inclusive encryption." \
                --text="7-Zip is running, please wait..." \
                --pulsate --auto-close --no-cancel); } 3>&1)
        fi

        if [ $? = 0 ]; then
            zenity --info --text="${message}"
        else
            zenity --error --text="{$message}"
        fi

    else
        exit 1
    fi
else
    # User has pressed cancel
    exit 1
fi