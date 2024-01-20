#!/bin/bash
#
# Removes all audio tracks from one or more selected videos.
# Different video types are possible as input at once (mp4, webm, flv, etc.).
# Stores the audioless video(s) in a user choice target folder.
# Optional add an suffix to the output files.
# Video quality is not affected.
#

# Select Video files.
# File name delimiter/seperator is U+2534 (BOX DRAWINGS LIGHT UP AND HORIZONTAL ┴)
sel_videos=$(zenity --file-selection \
    --title="Select Videos to have their audio track deleted (mixed Video types possible). (Cancel = Exit)" \
    --multiple --separator="┴" --file-filter=""*" "Desktop"" --filename="$1")
if [ $? != 0 ]; then
    zenity --info --title="Script aborted!" --text="Script aborted, nothings done."
    exit 1
fi

# Get current folder only if a script input file param is set.
dir=$(dirname "$1")

target_dir=$(zenity --file-selection \
    --title="Choose a target directory for the audioless videos. (Cancel = Exit)" \
    --file-filter=""*" "Desktop"" --directory --filename=$dir)
if [ $? != 0 ]; then
    zenity --info --title="Script aborted!" --text="Script aborted, nothings done."
    exit 1
fi

result=$(zenity --forms \
    --title="Removes all audio tracks from all previous selected Videos. Cancel = Exit Script." \
    --text="→ Set output name postfix.\n→ Set Override?" \
    --add-entry="Optional suffix for the output file name, default none." \
    --add-entry="Automatically override existing output file (y/n), default n")

if [ $? = 0 ]; then

    suffix="$(echo "$result"| cut -d '|' -f 1)"
    override="$(echo "$result"| cut -d '|' -f 2)"
    if [ "$override" != "y" ]; then
        override="n"
    fi
else
    zenity --info --title="Script aborted!" --text="Script aborted, nothings done."
    exit 1
fi

# Loops through all selected video files.
# File name delimiter/seperator is U+2534 (BOX DRAWINGS LIGHT UP AND HORIZONTAL ┴)
IFS="┴"
declare -i audio_removed_cnt=0
declare -i sel_vid_total=$(echo "$sel_videos"|awk -F'┴' '{print NF}')
for input_video in $sel_videos; do

    filename=$(basename -- "$input_video")
    ext="${filename##*.}"
    name="${filename%.*}"
    targetPath="${target_dir}/${name}${suffix}.${ext}"

    if [ -f "$targetPath" ] && [ "$override" == "n" ]; then
        continue
    fi

    # Checks if the video is corrupted.
    probe=$(ffprobe "$input_video" 2>&1)
    if [ $? -ne 0 ]; then
        zenity --error --text="${probe}\n\nProcess the next Video..."
        continue
    fi
    # Checks whether the video even has an audio track.
    ffprobe -loglevel error -select_streams a \
            -show_entries stream=codec_type -of csv=p=0 "$input_video" | grep audio >/dev/null 2>&1
    if [ $? = 0 ]; then

        msg=$(ffmpeg "-${override}" -i "$input_video" -map 0 -map -0:a -c copy "${targetPath}" 2>&1)
        if [ $? = 0 ]; then
            ((audio_removed_cnt++))
        else
            zenity --error --text="$msg"
        fi
    fi
done
fin_text="${audio_removed_cnt} of ${sel_vid_total} Videos was the Audio removed."
zenity --info --title="Audio removing finished." --text="$fin_text"