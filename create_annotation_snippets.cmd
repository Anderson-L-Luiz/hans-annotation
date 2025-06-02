: # Create annotation snippets for later publishing
:<<"::CMDLITERAL"
@ECHO OFF
GOTO :CMDSCRIPT
::CMDLITERAL
#!/bin/bash

: # if [[ ! -f ./scripts/ffmpeg ]]
: # then
: #     wget -O scripts/ffmpeg.tar.xz https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-$arch-static.tar.xz
: #     tar -xvf ffmpeg.tar.xz -C scripts/ --strip-components=1
: #     chmod +x scripts/ffmpeg
: #     chmod +x scripts/ffprobe
: # fi

: # Parameters
videoFile=""
language="de"
showHelp=0
segmentationTime=7
: # Engine 'mod9' or 'whisper'
engine="mod9"

while getopts e:f:l:t:h flag
do
    case "${flag}" in
        e) engine=$OPTARG;;
        f) videoFile=$OPTARG;;
        l) language=$OPTARG;;
        t) segmentationTime=$OPTARG;;
        h) showHelp=1;;
    esac
done

if [[ $showHelp -eq 1 ]] || [[ $videoFile = "" ]];
then
    echo "Create annotation snippets for later publishing"
    echo "Usage:"
    echo "  create_annotation_snippets.cmd -f <video-file> [-l <language>] [-e <engine-name>] [-t <interval>]"
    echo "Parameters: "
    echo "  -e: ASR engine, values: 'mod9', 'whisper'; default: 'mod9'"
    echo "  -f: Video file"
    echo "  -l: Language of the video file, default: 'de', values: 'en', 'de'"
    echo "  -t: Time interval for segmentation in seconds, default: 7"
    echo "Example:"
    echo "  create_annotation_snippets.cmd -f example-files/sintel/videos/Sintel.test.mp4 -l en"
else
    : # Copy video to a unique folder with uuid
    uuid=$(uuidgen)
    uuid=$(echo "$uuid" | tr '[:upper:]' '[:lower:]')
    videoFilename=$(basename "$videoFile")
    videoName="${videoFilename%.*}"
    videoFolder="${videoName}_$uuid"
    : # Create folder for output video, audio and transcript data
    mkdir "$videoFolder"

    ffmpeg -i "$videoFile" -vcodec copy -acodec copy -movflags faststart "$videoFolder/$uuid.mp4"

    : # Convert original video audio stream at 16000 Hz sample rate to a mono PCM wav file with signed, 16 bit, little endian
    ./scripts/convert.sh -i "$videoFolder"

    : # Create transcript and transcript.html using mod9 or whisper engine
    ./scripts/transcribe_${engine}.sh -i "$videoFolder"  -l "$language"
    if [[ $? -gt 0 ]]
    then
        "Unexpected error during transcribe_${engine}.sh occured!"
        exit 1
    fi

    : # Create video snippets in splitted folder
    mkdir "$videoFolder/splitted"

    : # Find times to split video based on word boundaries of mod9 output and create transcript snippets
    python3 ./scripts/define_segments.py -i "$videoFolder/$uuid.json" -a "$videoFolder/$uuid.wav" -o "$videoFolder/$uuid.csv" -d "$videoFolder/splitted" -t "$segmentationTime"
    if [[ $? -gt 0 ]]
    then
        "Unexpected error during define_segments.py occured!"
        exit 1
    fi

    : # Convert original video to multiple splitted video snippets
    ./scripts/split.sh -i "$videoFolder/$uuid.mp4" -s "$videoFolder/$uuid.csv" -o "$videoFolder/splitted"
    if [[ $? -gt 0 ]]
    then
        "Unexpected error during split.sh occured!"
        exit 1
    fi

    : # Convert splitted videos audio stream at 16000 Hz sample rate to a mono PCM wav file with signed, 16 bit, little endian
    ./scripts/convert.sh -i "$videoFolder/splitted"
    if [[ $? -gt 0 ]]
    then
        "Unexpected error during convert.sh occured!"
        exit 1
    fi
fi
exit $?

:CMDSCRIPT
ECHO Windows is currently not supported
