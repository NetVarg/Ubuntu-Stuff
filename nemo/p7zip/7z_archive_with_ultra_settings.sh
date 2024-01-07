#!/bin/bash
#
# The prerequisite is that 'p7zip-full' is installed.
# Adds all files or directories to archive archive.7z using "ultra settings".


# Extract the first file or directory name from the input string
# used as default archive name.
archName=$(basename -- "$1")

usr_dir=$(zenity --file-selection \
                 --title="Choose a directory (Cancel=No 7z compression)" \
                 --file-filter=""*" "Desktop"" --directory)
if [ $? = 0 ]; then 
    usr_file=$(zenity  --entry --width=600 \
                       --title="Archive name (Cancel=No 7z compression)" \
                       --text="Use the predefined filename or modify it" \
                       --entry-text="${usr_dir}/${archName}.7z")
    
    if [ $? = 0 ]; then
        # Adds all files or directories to archive using "ultra settings".
        message=$(7z a -t7z -m0=lzma -mx=9 -mfb=64 -md=32m -ms=on \
                       "${usr_file}" "$@")
        if [ $? = 0 ]; then
            zenity  --info --text="${message}"
        else
            zenity  --error --text="{$message}"
        fi
    else
        exit 1
    fi
else
    # User has pressed cancel
    exit 1
fi