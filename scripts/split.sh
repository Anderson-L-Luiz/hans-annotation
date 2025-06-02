#!/bin/bash

showHelp=0
download=0
split=0
inputFile=""
downloadUrl=""
outputFolder="."
verbose=0

#set -x
set -e

while getopts d:hi:o:s:v flag
do
    case "${flag}" in
        h) showHelp=1;;
        d) download=1; split=1; downloadUrl=$OPTARG;;
        i) split=1; inputFile=$OPTARG;;
        o) outputFolder=$OPTARG;;
        s) splitTimesFile=$OPTARG;;
        v) verbose=1;;
    esac
done

if [[ $showHelp -eq 1 ]] || [[ $split -eq 0 ]]
then
    echo "Splits a video file into multiple video segement files"
    echo "Usage:"
    echo "  split.sh ( -i <input-file> | -d <filename-to-url> ) -o <output-folder> [-s <split-times-file> -v]"
    echo "Parameters: "
    echo "  -i: The input video file"
    echo "  -d: Download input video file from DOWNLOAD_URL env and use filename for download"
    echo "  -o: The output folder for the video segment files"
    echo "  -s: The csv file containing the split times and split ids"
    echo "  -v: Verbose output"
    echo "Example:"
    echo "  split.sh -i Sintel.test.mp4 -s Sintel.test.csv -o /tmp"
else
    
    getSeconds() {
        local seconds=$(echo $1 | awk -F: '{ print ($1 * 3600) + ($2 * 60) + $3 }')
        echo $seconds
    }

    # trap ctrl-c and call ctrl_c()
    trap ctrl_c INT

    function ctrl_c() {
        echo ""
        echo "** Stopped with CTRL-C"
        rm -Rf $outputFolder/*
        echo "** Removed files from output folder"
        exit 1
    }

    if [[ $download -eq 1 ]]
    then
        #rm -Rf $outputFolder/*
        MY_SCRIPT_VARIABLE=""
        if [[ -z "${DOWNLOAD_URL}" ]]; then
          echo "** Error DOWNLOAD_URL not set in environment!"
          exit 1
        else
          MY_SCRIPT_VARIABLE="${DOWNLOAD_URL}"
        fi
        curl "$MY_SCRIPT_VARIABLE" --output "./temp_input/$downloadUrl"
        files=(./temp_input/*)
        inputFile="${files[0]}"
    fi
    if [[ $split -eq 1 ]]
    then
        echo "Starting segmentation of video file:"
        echo "- inputFile: $inputFile"
        
        echo "Creating segments:"
        outputFile=""
        cpuCount=$(getconf _NPROCESSORS_ONLN)
        cpuCount=$(($cpuCount / 2))
        pids=""
        if [[ $cpuCount -le 0 ]]
        then
            cpuCount=1
        fi

        c=0
        while IFS= read -r line; do
            arr+=("$line")
        done < "$splitTimesFile"
        for line in "${arr[@]}"
        do
            if [[ $c -gt 0 ]]
            then
                if ! ((c % cpuCount)); then
                    echo "Waiting for the next $cpuCount tasks to finish."
                    wait $pids
                    pids=""
                fi
            fi
            arrLine=(${line//;/ })
            startTime=${arrLine[0]} 
            targetTime=${arrLine[1]}
            outputFile="${arrLine[2]}.mp4"
            echo "- Segment with filename $outputFile"
            if [[ $outputFile == ".mp4" ]]
            then
                echo "Output filename invalid!"
                exit 1
            fi
            if [[ $verbose -eq 1 ]]
            then
                ffmpeg -y -i $inputFile -ss $startTime -to $targetTime \
                -vsync vfr \
                -c:v libx264 -profile:v high -level:v 3.1 -crf 18 -b:v 4M \
                -c:a aac -b:a 256k -ac 1 -ar 48000 \
                -vf "scale=1280x720:force_original_aspect_ratio=decrease,pad=1280:720:-1:-1:color=black" -aspect "16:9" \
                -tune zerolatency -pix_fmt yuv420p "$outputFolder/$outputFile" &
            else
                ffmpeg -y -i $inputFile -ss $startTime -to $targetTime \
                -vsync vfr \
                -c:v libx264 -profile:v high -level:v 3.1 -crf 18 -b:v 4M \
                -c:a aac -b:a 256k -ac 1 -ar 48000 \
                -vf "scale=1280x720:force_original_aspect_ratio=decrease,pad=1280:720:-1:-1:color=black" -aspect "16:9" \
                -tune zerolatency -pix_fmt yuv420p "$outputFolder/$outputFile" > /dev/null 2>&1 &
            fi
            pids="$pids $!"
            c=$((c+1))
        done
        wait $pids
    fi
    exit $?
fi
