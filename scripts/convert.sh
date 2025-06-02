#!/bin/bash

showHelp=0
convert=0
inputFolder="."
verbose=0

#set -x
set -e

while getopts hi:v flag
do
    case "${flag}" in
        h) showHelp=1;;
        i) convert=1; inputFolder=$OPTARG;;
        v) verbose=1;;
    esac
done

if [[ $showHelp -eq 1 ]] || [[ $convert -eq 0 ]]
then
    echo "Converts all video files in a folder to wav files"
    echo "Usage:"
    echo "  convert.sh -i <input-folder> [-v]"
    echo "Parameters: "
    echo "  -i: The input video file folder"
    echo "  -v: Verbose output"
    echo "Example:"
    echo "  convert.sh -i temp/splitted"
else
    files_in_folder=$(find "$inputFolder" -name "*.mp4" | sort | uniq -u)
    echo "Converting the following files to wav:"
    echo "$files_in_folder"
    for videofile in $files_in_folder; do
        videofilename=$(basename $videofile)
        outputFile="${videofilename%%.mp4}.wav"
        echo "Converting $inputFolder/$videofilename to $inputFolder/$outputFile"
        ffmpeg -i "$inputFolder/$videofilename" -vn -acodec pcm_s16le -ar 16000 -ac 1 "$inputFolder/$outputFile"
        if [[ $? -gt 0 ]]
        then
            "Unexpected error during convert.sh occured!"
            exit 1
        fi
    done
    echo "Finished conversion of $inputFolder"
    exit $?
fi
