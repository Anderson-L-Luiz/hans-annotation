: # Create annotation tasks for a video file on the labelstud.io instance
:<<"::CMDLITERAL"
@ECHO OFF
GOTO :CMDSCRIPT
::CMDLITERAL
#!/bin/bash

os=$(uname -s | tr '[:upper:]' '[:lower:]')
arch=$(uname -m)
if [[ $arch -eq "x86_64" ]]; then
    arch="amd64"
fi

if [[ ! -f ./scripts/mc ]]
then
    wget -O scripts/mc https://dl.min.io/client/mc/release/$os-$arch/mc 
    chmod +x scripts/mc
fi

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
videoTitle=""
metadataFile=""
showHelp=0
server="localhost"
segmentationTime=7
snippetTemplate="standard"
warmupId=""
: # Engine 'mod9' or 'whisper'
engine="mod9"

while getopts e:f:l:t:m:s:x:p:w:h flag
do
    case "${flag}" in
        e) engine=$OPTARG;;
        f) videoFile=$OPTARG;;
        l) language=$OPTARG;;
        t) videoTitle=$OPTARG;;
        m) metadataFile=$OPTARG;;
        s) server=$OPTARG;;
        x) segmentationTime=$OPTARG;;
        p) snippetTemplate=$OPTARG;;
        w) warmupId=$OPTARG;;
        h) showHelp=1;;
    esac
done

if [[ $showHelp -eq 1 ]] || [[ $videoFile = "" ]];
then
    echo "Create annotation tasks for a video file on the labelstud.io instance"
    echo "Usage:"
    echo "  create_annotation_task.cmd -f <video-file> -l <language> -t <video-title> -m <meta-data-file> [-e <engine-name>] [-s <hostname>] [-x <interaval-sec>] -p <project-template-alias> [-w <warmup-id>]"
    echo "Parameters: "
    echo "  -e: ASR engine, values: 'mod9', 'whisper'; default: 'mod9'"
    echo "  -f: Video file"
    echo "  -l: Language of the video file, default: 'de', values: 'en', 'de'"
    echo "  -t: Title of the video"
    echo "  -m: File containing metadata"
    echo "  -s: Server hostname, default: 'localhost'"
    echo "  -x: Time interval for segmentation in seconds, default: 7"
    echo "  -p: Template alias for video snippets project, default: 'standard', values: 'standard', 'science', 'warmup'"
    echo "  -w: Warmup ID to publish tasks to, only used if template alias (-p) is 'warmup', values: '01', '02', '03', '04'"
    echo "Example:"
    echo '  create_annotation_task.cmd -f example-files/sintel/videos/Sintel.test.mp4 -l en -t "Sintel Trailer" -m example-files/sintel/label.meta.json -p science'
else

    : # Clear temp folder
    if [[ -d temp ]]
    then
       rm -Rf temp
    fi
    mkdir temp

    : # Copy video to temp folder with uuid
    uuid=$(uuidgen)
    uuid=$(echo "$uuid" | tr '[:upper:]' '[:lower:]')
    ffmpeg -i "$videoFile" -vcodec copy -acodec copy -movflags faststart "temp/$uuid.mp4"

    : # Convert original video audio stream at 16000 Hz sample rate to a mono PCM wav file with signed, 16 bit, little endian
    ./scripts/convert.sh -i temp

    : # Create transcript and transcript.html using mod9 or whisper engine
    ./scripts/transcribe_${engine}.sh -i temp  -l "$language"
    if [[ $? -gt 0 ]]
    then
        "Unexpected error during transcribe_${engine}.sh occured!"
        exit 1
    fi

    : # Publish to default video_annotation project on labelstud.io
    if [[ $snippetTemplate != "warmup" ]]
    then
        projectId=$(python3 ./scripts/get_project_id_for_project_title.py "HAnS Video Annotation")
        ./scripts/publish.sh -i temp -p "$projectId" -s "$server" -f "$videoFile" -t "$videoTitle" -m "$metadataFile"
    fi

    : # Create video snippets in splitted folder
    mkdir temp/splitted

    : # Find times to split video based on word boundaries of mod9 output and create transcript snippets
    python3 ./scripts/define_segments.py -i "temp/$uuid.json" -a "temp/$uuid.wav" -o "temp/$uuid.csv" -d temp/splitted -t "$segmentationTime"
    if [[ $? -gt 0 ]]
    then
        "Unexpected error during define_segments.py occured!"
        exit 1
    fi

    : # Convert original video to multiple splitted video snippets
    ./scripts/split.sh -i "temp/$uuid.mp4" -s "temp/$uuid.csv" -o temp/splitted
    if [[ $? -gt 0 ]]
    then
        "Unexpected error during split.sh occured!"
        exit 1
    fi

    : # Convert splitted videos audio stream at 16000 Hz sample rate to a mono PCM wav file with signed, 16 bit, little endian
    ./scripts/convert.sh -i temp/splitted
    if [[ $? -gt 0 ]]
    then
        "Unexpected error during convert.sh occured!"
        exit 1
    fi

    : # Publish to default video_snippets project on labelstud.io
    if [[ $snippetTemplate == "standard" ]]
    then
        projectIdSnippets=$(python3 ./scripts/get_project_id_for_project_title.py "HAnS Video Snippets")
    elif [[ $snippetTemplate == "warmup" ]]
    then
        projectIdSnippets=$(python3 ./scripts/get_project_id_for_project_title.py "HAnS Video Snippets WarmUp $warmupId")
    elif [[ $snippetTemplate == "science" ]]
    then
        projectIdSnippets=$(python3 ./scripts/get_project_id_for_project_title.py "HAnS Video Snippets - Science")
    fi
    ./scripts/publish.sh -i temp/splitted -p "$projectIdSnippets" -s "$server" -f "$videoFile" -t "$videoTitle" -m "$metadataFile"
fi
exit $?

:CMDSCRIPT
ECHO Windows is currently not supported
