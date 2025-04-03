#!/bin/bash
#
# Convert and Compress videos.
# The script uses FFmpeg and zenity (display GTK+ dialogs).
# zenity is on an Ubuntu already installed.
#

# Exit script from a function
trap "exit 1" TERM
export TOP_PID=$$
# Script with Functions.
source ./compress_video_functions.sh

# #############################################################################
#       M A I N   P R O G R A M
# #############################################################################

# Choose the target video type (convert/compress to). Can be of the same
# type as the input video.
video_type=$(zenity --list --radiolist --width=600 --height=400 \
    --title="Choose the target video type (convert/compress to). Cancel = Exit Script." \
    --text="<i>Select output video type (container). Can be of the same type as the input video.</i>" \
    --hide-header --column "Select" --column="Video Type (Container)" \
    TRUE "mp4" \
    FALSE "webm")
if [ $? != 0 ]; then
    zenity --info --title="Script aborted!" --text="Script aborted, nothings done."
    exit 1
fi

# Select input video files.
# File name delimiter/seperator is U+2534 (BOX DRAWINGS LIGHT UP AND HORIZONTAL ┴)
sel_videos=$(zenity --file-selection --width=2000 \
    --title="Select Videos to have their convert (if not the same input type) and compress. (Cancel = Exit) \
Input videos can be of different types (container: mp4, flv, wmv,  etc.)." \
    --multiple --separator="┴" --file-filter=""*" "Desktop"" --filename="$1")
if [ $? != 0 ]; then
    zenity --info --title="Script aborted!" --text="Script aborted, nothings done."
    exit 1
fi

# Get current folder only if a script input file param is set.
dir=$(dirname "$1")

target_dir=$(zenity --file-selection \
    --title="Choose a target directory for the converted/compressed videos. (Cancel = Exit)" \
    --file-filter=""*" "Desktop"" --directory --filename=$dir)
if [ $? != 0 ]; then
    zenity --info --title="Script aborted!" --text="Script aborted, nothings done."
    exit 1
fi

case "$video_type" in
mp4)
    crf_text="CRF Constant Rate Factor. CRF affects the quality. CRF scale is 0–51."
    crf_text+="\n⎆ 0 is lossless."
    crf_text+="\n⎆ 23 is default crf."
    crf_text+="\n⎆ 51 is worst quality."
    crf_text+="\n⎆ 17–28 a subjectively sane range."
    preset_text="Choose a preset. Preset determines the encoding speed."
    preset_text+="\nThe slower the better quality but higher size.\nIf faster the"
    preset_text+=" poor quality but small size."
    preset_text+="\n⎆ medium, is default."
    preset_val="⎆ medium is default|⎆ veryslow|⎆ slower|⎆ slow|⎆ fast"
    preset_val+="|⎆ faster|⎆ veryfast|⎆ superfast|⎆ ultrafast"
    acc_text="Advanced Audio Coding (AAC). Set Constant Bit Rate (CBR) mode:"
    acc_text+="\n128 kBit/s for stereo, 384 kBit/s for 5.1 surround sound,"
    acc_text+="\ndefault is 128 kBit/s."
    applStd_text="Do you want your file to be compatible with"
    applStd_text+=" the Apple\n'industry standard' H.265?\nDefault is no."

    params=$(zenity --forms --separator="|" --width=800 \
        --title="Convert/Compress all videos. Cancel = Exit Script." \
        --text="→ Set vary optional parameters. <i>Output container is: $video_type</i>" \
        --add-entry="$(printf "$crf_text")" \
        --add-list="$(printf "$preset_text")" \
        --list-values="$(printf "$preset_val")" \
        --add-list="$(printf "$acc_text")" \
        --list-values="⎆ Audio Default 128 kBit/s|⎆ Audio 384 kBit/s" \
        --add-entry="$(printf "$(get_scale_text)")" \
        --add-list="$(printf "$(get_predef_scale_text)")" \
        --list-values="$(printf "$(get_predef_scale_val)")" \
        --add-list="$(printf "$applStd_text")" \
        --list-values="⎆ no Apple... is Default|⎆ yes Apple industry standard" \
        --add-entry="$(printf "$(get_suffix_text)")" \
        --add-list="$(printf "$(get_overr_text)")" \
        --list-values="⎆ no override is default|⎆ yes override")

    if [ $? = 0 ]; then
        # Because params delimiter has commas but only for --add-list, remove all commas.
        # params='51|⎆ ultrafast,|⎆ 384 kBit/s,|/2|⎆ yes,|xxxx|⎆ yes'
        params="$(echo "$params" | sed -E 's/,//g')"

        crf="$(echo "$params" | cut -d '|' -f 1)"
        if [ -z "$crf" ]; then
            crf="23"
        else
            ask_int_title="CRF must be an positive integer. Cancel = Exit Script."
            if [[ "$crf" =~ ^[0-9]+$ ]]; then
                if ((crf < 0 || crf > 51)); then
                    crf="$(ask_corrected_integer "$ask_int_title" "$crf_text" "23" "0" "51")"
                fi
            else
                crf="$(ask_corrected_integer "$ask_int_title" "$crf_text" "23" "0" "51")"
            fi
        fi

        preset="$(echo "$params" | cut -d '|' -f 2 |
            sed -E 's/^. ([a-z]+)\s?i?.*$/\1/; s/^$/medium/')"

        acc="$(echo "$params" | cut -d '|' -f 3 |
            sed -E 's/^.+ ([0-9]+) .+$/\1/; s/^$/128/')"

        scl_hand_param="$(echo "$params" | cut -d '|' -f 4)"
        if [[ -z "$scl_hand_param" ]]; then
            scl_list="$(echo "$params" | cut -d '|' -f 5)"
            if [[ -z "$scl_list" ]]; then
                # Default is no scaling.
                scale="iw:ih"
            else
                # Use predefined scale.
                scale="$(echo "$scl_list" | sed -E 's/^.*: (.*)$/\1/')"
            fi
        else
            # Use scale entered by hand.
            scale="$(get_scale "$scl_hand_param")"
        fi

        applStd="$(echo "$params" | cut -d '|' -f 6 |
            sed -E 's/^.*no.*$/n/; s/^.*yes.*$/y/; s/^$/n/')"

        suffix="$(echo "$params" | cut -d '|' -f 7)"
        override="$(echo "$params" | cut -d '|' -f 8 |
            sed -E 's/^.*no.*$/n/; s/^.*yes.*$/y/; s/^$/n/')"
    else
        zenity --info --title="Script aborted!" --text="Script aborted, nothings done."
        exit 1
    fi
    ;;
webm)
    crf_text="The CRF value can be from 0–63. Lower values mean better quality."
    crf_text+="\n⎆ Recommended values range from 15–35"
    crf_text+="\n⎆ With 31 being recommended for 1080p HD video"
    crf_text+="\n⎆ No entry = Default is 31"
    opus_text="Opus is the Audio Codec encoder."
    opus_text+="\n⎆ Audio Range bits/s 500-512000"
    opus_text+="\n⎆ No entry = Default 96000"
    deadl_text="Deadline/Quality can be set to realtime, good, or best."
    deadl_text+="\n⎆ good is the default and recommended for most applications."
    deadl_text+="\n⎆ best is recommended if you have lots of time and want the best compression efficiency."
    deadl_text+="\n⎆ realtime is recommended for live/fast encoding. It does a single pass run, this will"
    deadl_text+="\n⁘ result in less efficient compression. Play with 'CRF' and 'Deadline/Quality' for a"
    deadl_text+="\n⁘ passable quality with little time investment, e.g. CRF=24, Deadline=5."
    deadl_val="⎆ good is default|⎆ best|⎆ realtime"
    cpu_text="CPU Utilization/Speed sets how efficient the compression will be."
    cpu_text+="\n⎆ When Deadline/Quality is good or best, values can"
    cpu_text+="\n    be set between 0 and 5. The default is 0."
    cpu_text+="\n⎆ Using 1 or 2 will increase encoding speed but less quality and rate control accuracy."
    cpu_text+="\n⎆ 4 or 5 will turn off rate distortion optimization, having even more less of quality."
    cpu_text+="\n⎆ When the deadline/quality is set to realtime, the available values are 0 to 8"
    cpu_val="⎆ 0 is default|⎆ 1|⎆ 2|⎆ 3|⎆ 4|⎆ 5|⎆ 6|⎆ 7|⎆ 8"

    params=$(zenity --forms --separator="|" --width=900 \
        --title="Convert/Compress all videos. Cancel = Exit Script." \
        --text="→ Set vary optional parameters. <i>Output container is: $video_type</i>" \
        --add-entry="$(printf "$crf_text")" \
        --add-entry="$(printf "$opus_text")" \
        --add-list="$(printf "$deadl_text")" \
        --list-values="$(printf "$deadl_val")" \
        --add-list="$(printf "$cpu_text")" \
        --list-values="$(printf "$cpu_val")" \
        --add-entry="$(printf "$(get_scale_text)")" \
        --add-list="$(printf "$(get_predef_scale_text)")" \
        --list-values="$(printf "$(get_predef_scale_val)")" \
        --add-entry="$(printf "$(get_suffix_text)")" \
        --add-list="$(printf "$(get_overr_text)")" \
        --list-values="⎆ no override is default|⎆ yes override")

    if [ $? = 0 ]; then
        # Because params delimiter has commas but only for --add-list, remove all commas.
        # params='51|⎆ ultrafast,|⎆ 384 kBit/s,|/2|⎆ yes,|xxxx|⎆ yes'
        params="$(echo "$params" | sed -E 's/,//g')"

        crf="$(echo "$params" | cut -d '|' -f 1)"
        if [ -z "$crf" ]; then
            crf="31"
        else
            ask_int_title="CRF must be an positive integer. Cancel = Exit Script."
            if [[ "$crf" =~ ^[0-9]+$ ]]; then
                if ((crf < 0 || crf > 63)); then
                    crf="$(ask_corrected_integer "$ask_int_title" "$crf_text" "31" "0" "63")"
                fi
            else
                crf="$(ask_corrected_integer "$ask_int_title" "$crf_text" "31" "0" "63")"
            fi
        fi

        opus="$(echo "$params" | cut -d '|' -f 2)"
        if [ -z "$opus" ]; then
            opus="96000"
        fi
        deadl="$(echo "$params" | cut -d '|' -f 3 |
            sed -E 's/^. ([a-z]{4,8})\s?i?.*$/\1/; s/^$/good/')"

        cpu_used="$(echo "$params" | cut -d '|' -f 4 |
            sed -E 's/^.+ ([0-9]{1}).*$/\1/; s/^$/0/')"

        scl_hand_param="$(echo "$params" | cut -d '|' -f 5)"
        if [[ -z "$scl_hand_param" ]]; then
            scl_list="$(echo "$params" | cut -d '|' -f 6)"
            if [[ -z "$scl_list" ]]; then
                # Default is no scaling.
                scale="iw:ih"
            else
                # Use predefined scale.
                scale="$(echo "$scl_list" | sed -E 's/^.*: (.*)$/\1/')"
            fi
        else
            # Use scale entered by hand.
            scale="$(get_scale "$scl_hand_param")"
        fi

        suffix="$(echo "$params" | cut -d '|' -f 7)"
        override="$(echo "$params" | cut -d '|' -f 8 |
            sed -E 's/^.*no.*$/n/; s/^.*yes.*$/y/; s/^$/n/')"
    else
        zenity --info --title="Script aborted!" --text="Script aborted, nothings done."
        exit 1
    fi
    ;;
esac

# Loops through all selected video files.
# File name delimiter/seperator is U+2534 (BOX DRAWINGS LIGHT UP AND HORIZONTAL ┴)
IFS="┴"
declare -i processed_cnt=0
declare -i loop_cnt=0
declare -i sel_vid_total=$(echo "$sel_videos" | awk -F'┴' '{print NF}')
# Flag for allowing scale auto-correction.
declare autocorrect="x"
# Save original entered scale.
declare orig_scale=$scale
rm -f ./compress_video_mp4.log
rm -f ./compress_video_webm.log
process=$({ $(
    for input_video in $sel_videos; do
        ((loop_cnt++))
        filename=$(basename -- "$input_video")
        ext="$video_type"
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

        case "$video_type" in
        mp4)
            # Gets back original entered scale ( if previous override in the loop).
            scale=$orig_scale
            scale_corrected="n"
            # Check if width and height values all even numbers, a must for mp4.
            if [[ "$scale" == "iw:ih" ]]; then
                # Gets the scale of video.
                probe_s=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height \
                    -of csv=s=x:p=0 "$input_video" | sed -e 's/x/:/')
                # Check if w & h values even numbers.
                adj_scale=$(w_and_h_as_even $probe_s)
                if [[ "$adj_scale" =~ ^.*A$ ]]; then
                    scale=$(echo "$adj_scale" | sed -e 's/A//')
                    scale_corrected="y"
                else
                    scale="iw:ih" # Video Scale has even numbers, ok to convert video.
                fi
            # If format: "trunc(iw/$divi)*2:trunc(ih/$divi)*2" no even-check.
            elif [[ "$scale" =~ ^.*iw/.*$ ]]; then
                :
            # If user has entered the scale, checks if values even numbers.
            elif [[ "$scale" =~ ^-?[0-9]+:-?[0-9]+$ ]]; then
                adj_scale=$(w_and_h_as_even $scale)
                if [[ "$adj_scale" =~ ^.*A$ ]]; then
                    scale=$(echo "$adj_scale" | sed -e 's/A//')
                    scale_corrected="y"
                fi
            # If format: "iw*$multi:ih*$multi"
            elif [[ "$scale" =~ ^iw\*.*$ ]]; then
                mult=$(echo "$scale" | sed -E 's/^.*:ih\*//')
                if [[ $(($mult % 2)) != 0 ]]; then
                    probe_s=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height \
                        -of csv=s=x:p=0 "$input_video")
                    mul_w=$(echo "$probe_s" | cut -d 'x' -f 1)
                    mul_w=$((mul_w * mult))
                    mul_h=$(echo "$probe_s" | cut -d 'x' -f 2)
                    mul_h=$((mul_h * mult))
                    # Check if w & h values even numbers.
                    adj_scale=$(w_and_h_as_even "$mul_w:$mul_h")
                    if [[ "$adj_scale" =~ ^.*A$ ]]; then
                        scale=$(echo "$adj_scale" | sed -e 's/A//')
                        scale_corrected="y"
                    fi
                fi
            else
                zenity --info --title="Script aborted!" --text="Wrong Scale format: $scale"
                exit 1
            fi
            if [[ "$scale_corrected" == "y" ]] && [[ "$autocorrect" == "x" ]]; then
                auto_sc_text="Autocorrect the scale for ALL selected videos?"
                auto_sc_text+="\n⎆ yes = Automatically correct all videos."
                auto_sc_text+="\n⎆ no = NO video will be auto-corrected, these will be skipped."
                autocorrect=$(zenity --forms \
                    --title="Autocorrects the scale of videos. Cancel = Exit Script." \
                    --width=600 \
                    --text="The scaling needs to be adjusted for mp4." \
                    --add-list="$(printf "$auto_sc_text")" \
                    --list-values='⎆ no|⎆ yes')

                if [[ $? == 0 ]]; then
                    autocorrect="$(echo "$autocorrect" |
                        sed -E 's/^.*no$/n/; s/^.*yes$/y/; s/^$/n/')"
                else
                    zenity --info --title="Script aborted!" --text="Script exited."
                    exit 1
                fi
            fi
            if [[ "$scale_corrected" == "y" ]] && [[ "$autocorrect" == "n" ]]; then
                # Skip this video, no compress/convert ################################
                continue
            fi

            if [[ "$applStd" == "n" ]]; then
                msg=$(ffmpeg "-${override}" -i "$input_video" -vf "scale=$scale" \
                    -c:v libx265 -crf $crf -preset $preset \
                    -c:a aac -b:a ${acc}k "${targetPath}" >>compress_video_mp4.log 2>&1)
            else
                # Makes file compatible with Apple "industry standard" H.265, -tag:v hvc1
                msg=$(ffmpeg "-${override}" -i "$input_video" -vf "scale=$scale" \
                    -c:v libx265 -crf $crf -preset $preset -tag:v hvc1 \
                    -c:a aac -b:a ${acc}k "${targetPath}" >>compress_video_mp4.log 2>&1)
            fi
            if [ $? = 0 ]; then
                ((processed_cnt++))
            else
                zenity --error --text="$(last_30_lines "$msg")"
            fi
            ;;
        webm)
            if [[ "$deadl" != "realtime" ]]; then
                # Convert/compress with two pass mode.
                msg=$(ffmpeg "-${override}" -i "$input_video" -vf "scale=$scale" \
                    -c:v libvpx-vp9 -b:v 0 -crf $crf -pass 1 -deadline $deadl \
                    -cpu-used $cpu_used -an -f null /dev/null &&
                    ffmpeg "-${override}" -i "$input_video" -vf "scale=$scale" \
                        -c:v libvpx-vp9 -b:v 0 -crf $crf -pass 2 -deadline $deadl \
                        -cpu-used $cpu_used -c:a libopus \
                        -b:a $opus "${targetPath}" >>compress_video_webm.log 2>&1)
            else
                # Single-Pass mode because param deadline is 'realtime'.
                msg=$(ffmpeg "-${override}" -i "$input_video" -vf "scale=$scale" \
                    -c:v libvpx-vp9 -crf $crf -b:v 0 -deadline $deadl \
                    -cpu-used $cpu_used -c:a libopus \
                    -b:a $opus "${targetPath}" >>compress_video_webm.log 2>&1)
            fi
            if [ $? = 0 ]; then
                ((processed_cnt++))
            else
                zenity --error --text="$(last_30_lines "$msg")"
            fi
            ;;
        esac

        if [ $loop_cnt -eq $sel_vid_total ]; then
            echo "$processed_cnt"
        fi
    done 2>&1 |
        tee /dev/fd/3 |
        zenity --progress \
            --title="Converting, compressing has started." \
            --text="Please wait..." \
            --pulsate --no-cancel --auto-close
); } 3>&1)
if [ $? = 0 ]; then
    if [ -z "$process" ]; then
        process="0"
    else
        if [ $"$video_type" == "webm" ]; then
            # Remove the much frame info lines
            process="$(echo "$process" | sed -z -e 's/frame=.*was encoded//g')"
        fi
        process="$(last_30_lines "$process")"
    fi
    fin_text="$process of $sel_vid_total Videos was converted/compressed."

    log_text="Open Log File with text editor?"
    log_title="Finished. Cancel = Exit Script."
    exit_code_script=0
else
    process="$(last_30_lines "$process")"
    fin_text="$(printf "$process" | fold -sw 95)"
    log_text="Open ERROR Log File with text editor?"
    log_title="ERROR on converting/compressing. Cancel = Exit Script."
    exit_code_script=1
fi

grep -iE 'warning|error' ./compress_video_$video_type.log >/dev/null 2>&1
if [[ $? == 0 ]]; then
    log_text=$(echo "$log_text" |
        sed -E 's/\?$/?\n⍄ A Warning or Error text exists in the log file!\n/')
else
    log_text+="\n\n\n " # Move text to up.
fi

cleanup_text="Cleanup: Log files 'compress_video_xxx.log' and"
cleanup_text+="\n'ffmpeg2pass-x.log' (webm only) can be removed by hand."
show_log=$(zenity --forms \
    --title="$log_title" \
    --width=600 \
    --text="$(printf "$fin_text")" \
    --add-list="$(printf "$log_text")" \
    --list-values='⎆ no|⎆ yes' \
    --add-password="$(printf "$cleanup_text")")

if [[ $? == 0 ]]; then
    # Because params delimiter has commas but only for --add-list, remove all commas.
    # params='51|⎆ ultrafast,|⎆ 384 kBit/s,|/2|⎆ yes,|xxxx|⎆ yes'
    show_log="$(echo "$show_log" | sed -E 's/,//g')"
    show_log="$(echo "$show_log" | cut -d '|' -f 1)"

    if [[ "$show_log" =~ ^.*no$ ]]; then
        exit $exit_code_script
    else
        if [[ -f "./compress_video_$video_type.log" ]]; then
            type -a xdg-open >/dev/null 2>&1
            if [[ $? == 0 ]]; then
                xdg-open "./compress_video_$video_type.log"
            else
                zenity --error --title="Can't open log file!" \
                    --text="Please open log file: 'compress_video_$video_type.log' by hand."
            fi
        else
            zenity --info --title="No Log File!" \
                --text="Log file compress_video_$video_type.log doesn't exists."
            exit $exit_code_script
        fi
    fi
else
    exit $exit_code_script
fi
