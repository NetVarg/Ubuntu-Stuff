#!/bin/bash
#
# Remember selected file or folder for later diff with kdiff3.
# Save f1 file/folder path to file:
# /tmp/f1Path_29285c58-7c56-4a8d-8d66-1ad333d095da
# AND
# Diff with previous stored path.
# Restore f1 file/folder path for kdiff3 from file:
# /tmp/f1Path_29285c58-7c56-4a8d-8d66-1ad333d095da
#
# This script is called by following Nemo Actions:
# 'kdiff3 remember path for later diff.nemo_action',
# 'kdiff3 diff with previous stored path.nemo_action'

ISREMEMBER="${*: -1}"
F1PATH=/tmp/f1Path_29285c58-7c56-4a8d-8d66-1ad333d095da

if [ "$ISREMEMBER" == "////" ]; then

    cd /tmp
    echo "$1" >$F1PATH

    fileOrFolder="file"
    if [[ -d $1 ]]; then
        fileOrFolder="folder"
    fi

    message="<b>kdiff3 f1 $fileOrFolder path stored for a later diff.</b>\r"
    message+="Select now f2, optional f3 $fileOrFolder,\r"
    message+="start action: 'kdiff3 diff with PREVIOUS stored path'."
    notify-send -u normal \
        "File or Folder Path stored!" \
        "$message"

else
    cd /tmp
    PREV_F1=$(<$F1PATH)

    if [ $# -eq 1 ]; then
        /usr/bin/kdiff3 "$PREV_F1" "$1" >/dev/null 2>&1 &
    else
        /usr/bin/kdiff3 "$PREV_F1" "$1" "$2" >/dev/null 2>&1 &
    fi
fi
