#!/bin/bash
#
# The prerequisite is that 'p7zip-full' is installed.
# Extracts a 7z archive.
# Asks whether files can be overwritten.
# Asks for the zip password if necessary.

# Get current folder.
dir=$(dirname "$1")

echo "Select a directory to unpack into. See just opened folder dialog."

usr_dir=$(zenity --file-selection \
    --title="Select a directory to unpack into (Cancel=No unzip)" \
    --file-filter=""*" "Desktop"" --directory --filename=$dir)

if [ $? = 0 ]; then

    message=$(7z x -o"${usr_dir}" "$1" 2>&1 | tee /dev/tty)

    lines=$(echo "$message" | wc -l)

    if [[ lines -gt 40 ]]; then

        cut_off=$[lines-40]
        msg=". . . . . . . . . The $cut_off lines before were cut off.\nComplete text see in the Konsole.\n\n"
        # Only the last 40 lines are displayed
        msg+=$(echo "$message" | sed -ne':a;$p;N;40,$D;ba')
        zenity --info --text="$msg"

    else
        zenity --info --text="$message"
    fi
else
    # User has pressed cancel
    exit 1
fi
