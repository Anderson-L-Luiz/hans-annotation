: # Publish already transcribed videos and split annotation snippets on the labelstud.io instance
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
videoFolder=""
showHelp=0
server="http://10.50.1.41:8083"
videoFile=""
videoTitle=""
metadataFile=""
snippetTemplate="standard"
warmupId=""

while getopts i:s:f:t:m:p:w:h flag
do
    case "${flag}" in
        i) videoFolder=$OPTARG;;
        s) server=$OPTARG;;
        f) videoFile=$OPTARG;;
        t) videoTitle=$OPTARG;;
        m) metadataFile=$OPTARG;;
        p) snippetTemplate=$OPTARG;;
        w) warmupId=$OPTARG;;
        h) showHelp=1;;
    esac
done

if [[ $showHelp -eq 1 ]] || [[ $videoFolder = "" ]];
then
    echo "Publish already transcribed videos and split annotation snippets on the labelstud.io instance"
    echo "Usage:"
    echo "  publish_annotation_task.cmd -i <snippet-folder> -f <video-file> [-s <server-hostname>] -t <video-title> -m <meta-data-file> -p <project-template-alias> [-w <warmup-id>]"
    echo "Parameters: "
    echo "  -i: Folder containing snippets generated with `create_annotation_snippets.cmd`"
    echo "  -f: File of the original video"
    echo "  -s: Server hostname, default: "localhost"
    echo "  -t: Title of the video"
    echo "  -m: File containing metadata"
    echo "  -p: Template alias for video snippets project, default: 'standard', values: 'standard', 'science', 'warmup'"
    echo "  -w: Warmup ID to publish tasks to, only used if template alias (-p) is 'warmup', values: '01', '02', '03', '04'"
    echo "Example:"
    echo '  publish_annotation_task.cmd -i Sintel.test_5a171cb8-665e-4840-a2db-97527731394d -f example-files/sintel/videos/Sintel.test.mp4 -s localhost -t "Sintel Trailer" -m example-files/sintel/label.meta.json -p science'
else
    : # Publish to default video_annotation project on labelstud.io
    if [[ $snippetTemplate != "warmup" ]]
    then
        projectId=$(python3 ./scripts/get_project_id_for_project_title.py "HAnS Video Annotation")
        ./scripts/publish.sh -i "$videoFolder" -p "$projectId" -s "$server" -f "$videoFile" -t "$videoTitle" -m "$metadataFile"
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
    ./scripts/publish.sh -i "$videoFolder/splitted" -p "$projectIdSnippets" -s "$server" -f "$videoFile" -t "$videoTitle" -m "$metadataFile"
fi
exit $?

:CMDSCRIPT
ECHO Windows is currently not supported
