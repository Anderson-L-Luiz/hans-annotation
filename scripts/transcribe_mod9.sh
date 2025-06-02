#!/bin/bash

showHelp=0
transcribe=0
inputFolder="."
language="en"
verbose=0

# ASR engine configuration
asrEngineHost="gutmann.informatik.fh-nuernberg.de"
asrEnginePort=9900

#set -x
set -e

while getopts hi:l:v flag
do
    case "${flag}" in
        h) showHelp=1;;
        i) transcribe=1; inputFolder=$OPTARG;;
        l) language=$OPTARG;;
        v) verbose=1;;
    esac
done

if [[ $showHelp -eq 1 ]] || [[ $transcribe -eq 0 ]]
then
    echo "Transcribe all audio files in a folder to json files"
    echo "Usage:"
    echo "  recognize.sh -i <input-folder> [-v]"
    echo "Parameters: "
    echo "  -i: The input audio file folder"
    echo "  -v: Verbose output"
    echo "Example:"
    echo "  recognize.sh -i temp -l en"
else
    for audiofile in $(find "$inputFolder" -name "*.wav" | sort | uniq -u) ; do
        audiofilename=$(basename $audiofile)
        uuid="${audiofilename%.*}"
        outputFile="${audiofilename%.*}.asrengine.json"
        asrModel="${language}_video"
        echo "Using ASR model: $asrModel"

        echo "Checking mod9 health status"
        info=$(echo '{"command":"get-info"}' | nc -w 1 $asrEngineHost $asrEnginePort)
        if [[ ! $info == *"state"*":"*"ready"* ]]; then
            echo "Error: Engine not ready!"
            exit 1
        else
            echo "Engine ready!"
        fi

        echo "Transcribing $inputFolder/$audiofilename to $inputFolder/$outputFile"
        (echo '{"command": "recognize", "batch-threads": -1, "word-intervals": true, "word-confidence": true, "transcript-intervals": true, "word-alternatives-confidence": true, "word-alternatives": 3, "asr-model": "'"$asrModel"'" }'; cat $inputFolder/$audiofilename) | nc $asrEngineHost $asrEnginePort > $inputFolder/$outputFile

        wordcount=$(wc -c "$inputFolder/$outputFile" | awk '{print $1}')
        if [ "$wordcount" -lt 45 ]
        then
            echo "Error: Invalid raw recognition result!"
            exit 1
        fi

        # Convert result $uuid.asrengine.json to final asr result $uuid.json
        python3 scripts/convert_mod9_asr_result.py --input-file "$inputFolder/$outputFile" --language "$language" --output-file "$inputFolder/$uuid.json"

        # Create transcript html file for annotation from asr result $uuid.json
        python3 scripts/create_html_transcript.py --input-file "$inputFolder/$uuid.json" --output-file "$inputFolder/$uuid.html"
    done
    exit $?
fi
