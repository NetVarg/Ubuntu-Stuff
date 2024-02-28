#!/bin/bash
#
# Script with functions for script 'Convert and Compress videos'.
# The script uses zenity (display GTK+ dialogs).
# zenity is on an Ubuntu already installed.
#

# #############################################################################
#       Definition of  F U N C T I O N S
# #############################################################################

# Ask for corrected integer. Param1 = Title, Param2 = Text, Param3 = Initial value,
# Param4 = minimum value, Param5 = maximum value. Returns user corrected number.
function ask_corrected_integer() {
    corr_int=$(zenity --scale --title="$1" --text="$2" \
        --value="$3" --min-value="$4" --max-value="$5")
    if [ -z "$corr_int" ]; then
        zenity --info --title="Script aborted!" --text="Script aborted, nothings done."
        kill -s TERM $TOP_PID
    else
        echo "$corr_int"
    fi
}

function get_overr_text() {
    echo "Automatically override existing output file?\nDefault is no."
}

function get_predef_scale_text() {
    echo "⎆ Or use some predefined scales instead of typing by hand.\n \n \n "
}

function get_predef_scale_val() {
    local prescales_val="⎆ As input video: iw:ih|⎆ Half the size: trunc(iw/4)*2:trunc(ih/4)*2"
    prescales_val+="|⎆ Stretch double: iw*2:ih*2|⎆ 2k: 2048:1080|⎆ 4k: 4096:2160"
    prescales_val+="|⎆ hd480: 852:480|⎆ hd720: 1280:720|⎆ hd1080: 1920:1080|⎆ hvga: 480:320"
    prescales_val+="|⎆ nhd: 640:360|⎆ ntsc: 720:480|⎆ ntsc-film: 352:240|⎆ pal: 720:576"
    prescales_val+="|⎆ qhd: 960:540|⎆ qvga: 320:240|⎆ sntsc: 640:480|⎆ spal: 768:576"
    prescales_val+="|⎆ vga: 640:480|⎆ wqvga: 400:240|⎆ xga: 1024:768"
    echo "$prescales_val"
}

# Returns the scaling syntax based on the text entered by the user.
# Also checks the correctness of the input. Param1 = entered scale.
function get_scale() {
    if [ -z "$1" ]; then
        echo "iw:ih"

    elif [[ "$1" =~ ^/([1-9]+)$ ]]; then
        divi=$((2 * BASH_REMATCH[1]))
        echo "trunc(iw/$divi)*2:trunc(ih/$divi)*2"

    elif [[ "$1" =~ ^\*([1-9]+)$ ]]; then
        multi=${BASH_REMATCH[1]}
        echo "iw*$multi:ih*$multi"

    elif [[ "$1" =~ ^([0-9]+:[0-9]+)$ ]]; then
        echo ${BASH_REMATCH[1]}

    elif [[ "$1" =~ ^(-[12]:[0-9]+)$ ]]; then
        echo ${BASH_REMATCH[1]}

    elif [[ "$1" =~ ^([0-9]+:-[12])$ ]]; then
        echo ${BASH_REMATCH[1]}
    else
        chng_scale=$(zenity --forms --separator="|" \
            --title="Wrong scale format entered! Cancel = Exit Script." \
            --text="Please enter a correct scale" \
            --add-entry="$(printf "$(get_scale_text)")" \
            --add-list="Or use some predefined scales instead of typing by hand" \
            --list-values="$(printf "$(get_predef_scale_val)")")
        if [[ $? == 0 ]]; then
            chng_scale="$(echo "$chng_scale" | sed -E 's/,//g')"
            local sclhand="$(echo "$chng_scale" | cut -d '|' -f 1)"
            if [[ -z "$sclhand" ]]; then
                local scllist="$(echo "$chng_scale" | cut -d '|' -f 2)"
                if [[ -z "$scllist" ]]; then
                    get_scale "no-select"
                else
                    echo $scllist | sed -E 's/^.*: (.*)$/\1/'
                fi
            else
                get_scale "$sclhand"
            fi
        else
            kill -s TERM $TOP_PID
        fi
    fi
}

function get_scale_text() {
    local scale_text="Set Scaling, default is no scaling."
    scale_text+="\n⎆ Enter explicit width, height e.g. 320:240"
    if [[ $video_type == "mp4" ]]; then
        scale_text+="\n↯ mp4 requires even value of width and height,\ne.g. 321:240 is not allowed."
    fi
    scale_text+="\n⎆ Enter width or heigt keeping the Aspect Ratio e.g. 320:-2  -2:240"
    scale_text+="\n⎆ Half the size e.g. /2 or /3 or /4 etc."
    scale_text+="\n⎆ Stretch double e.g. *2 or *3 or *4 etc."
    echo "$scale_text"
}

function get_suffix_text() {
    local suf_text="Optional suffix for the output file name, default none."
    suf_text+="\n⎆ e.g. _xxxx is the suffix, result: input-name_xxxx.mp4"

    echo "$suf_text"
}

# Returns the last 30 lines of an input text.
# If input <30, returns the input text back.
function last_30_lines() {
    local lines=$(echo "$1" | wc -l)
    if [[ lines -gt 30 ]]; then
        local cut_off=$((lines - 30))
        local cutmsg=". . . . . . . . . The $cut_off lines before were cut off.\n\n"
        cutmsg+=$(echo "$1" | sed -ne':a;$p;N;30,$D;ba')
        echo "$cutmsg"
    else
        echo "$1"
    fi
}

# Returns width and/or heigth as even numbers, else the original value.
# When adjust made, appends flag A at the of w:h string i.e. w:hA
# Input params $1 format: width:height OR -2:height OR width:-2
# Check whether width and height are even numbers.
# libx265 require the size of width and height to be a multiple of 2.
function w_and_h_as_even() {
    local w=""
    local wIn=$(echo $1 | sed -E 's/:-?[0-9]+$//')
    local h=""
    local hIn=$(echo $1 | sed -E 's/^-?[0-9]+://')
    local c_flag=""
    if [[ $wIn < 0 ]]; then
        w=$wIn
    elif [[ $(($wIn % 2)) == 0 ]]; then
        w=$wIn
    else
        w=$(($wIn / 2 * 2))
        c_flag="A"
    fi
    if [[ $hIn < 0 ]]; then
        h=$hIn
    elif [[ $(($hIn % 2)) == 0 ]]; then
        h=$hIn
    else
        h=$(($hIn / 2 * 2))
        c_flag="A"
    fi
    echo "$w:$h$c_flag"
}
