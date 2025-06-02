#!/bin/bash

showHelp=0
transcribe=0
inputFolder="."
language="en"
verbose=0

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
    if [[ -d "scripts/_venv_whisper" ]]
    then
        source scripts/_venv_whisper/bin/activate
    else
        python3 -m venv scripts/_venv_whisper
        source scripts/_venv_whisper/bin/activate
        python3 -m pip install git+https://github.com/linto-ai/whisper-timestamped
    fi
    asrModel="large-v2"
    version_whisper=$(python3 scripts/get_version.py --package openai-whisper)
    version_whisper_timestamped=$(python3 scripts/get_version.py --package whisper_timestamped)
    verboseValue="False"
    if [[ $verbose -eq 1 ]]
    then
        verboseValue="True"
    fi
    for audiofile in $(find "$inputFolder" -name "*.wav" | sort | uniq -u) ; do
        audiofilename=$(basename $audiofile)
        uuid="${audiofilename%.*}"
        outputFile="${audiofilename}.words.json"
        outputFileConverted="${uuid}.json"
        outputFileTranscript="${uuid}.html"
        echo "Using whisper: ${asrModel}_${version_whisper}"

        echo "Transcribing $inputFolder/$audiofilename to $inputFolder/$outputFile"
        whisper_timestamped --model "$asrModel" --language "$language" --output_format "all" --task "transcribe" --threads 32 --fp16 "False" --verbose "$verboseValue" --output_dir "$inputFolder" "$inputFolder/$audiofilename"

        echo "Converting $inputFolder/$outputFile to $inputFolder/$outputFileConverted"
        python3 scripts/convert_whisper_asr_result.py --input-file "$inputFolder/$outputFile" --output-file "$inputFolder/$outputFileConverted" --model "$asrModel" --language "$language" --version "${version_whisper}" --version-timestamped "${version_whisper_timestamped}"

        echo "Converting $inputFolder/$outputFileConverted to $inputFolder/$outputFileTranscript"
        python3 scripts/create_html_transcript.py --input-file "$inputFolder/$outputFileConverted" --output-file "$inputFolder/$outputFileTranscript"
    done
    exit $?
fi
