#!/bin/bash

showHelp=0
publish=0
inputFolder="."
projectId="2"
verbose=0
videoFile=""
videoTitle=""
metadataFile=""

# minio configuration
database="localhost"
port=9003
bucket="assets"
bucket_tasks="tasks"
MINIO_ROOT_USER="minio"
MINIO_ROOT_PASSWORD="minio123"
server="http://10.50.1.41:8083"

#set -x
set -e

while getopts hi:s:p:f:t:m:v flag
do
    case "${flag}" in
        h) showHelp=1;;
        i) publish=1; inputFolder=$OPTARG;;
        s) server=$OPTARG;;
        p) projectId=$OPTARG;;
        f) videoFile=$OPTARG;;
        t) videoTitle=$OPTARG;;
        m) metadataFile=$OPTARG;;
        v) verbose=1;;
    esac
done

if [[ $showHelp -eq 1 ]] || [[ $publish -eq 0 ]]
then
    echo "Publish all files and import annotation task"
    echo "Usage:"
    echo "  publish.sh -i <input-folder> -p <project-id> [-s <hostname>] -f <input-file> -t <title> -m <meta-data-file> [-v]"
    echo "Parameters: "
    echo "  -i: The input file folder"
    echo "  -p: Annotation project id as text"
    echo "  -s: Server hostname running the minio service, default: localhost"
    echo "  -f: Video file"
    echo "  -t: Title of the video"
    echo "  -m: File containing metadata"
    echo "  -v: Verbose output"
    echo "Example:"
    echo "  publish.sh -i temp/splitted -p 2 -s localhost -f file.mp4 -t 'Video Title' -m meta.json"
else
    cwd=$(pwd)

    # Initialize minio
    $cwd/scripts/mc alias set minio http://$database:$port $MINIO_ROOT_USER $MINIO_ROOT_PASSWORD

    # Allow anonymous download on minio bucket
    $cwd/scripts/mc anonymous set download minio/$bucket
    $cwd/scripts/mc anonymous set download minio/$bucket_tasks

    # Publish video on minio: https://docs.min.io/minio/baremetal/reference/minio-mc/mc-share-download.html
    minio_upload () {
      uploadFile="$1/$2$3"
      if [[ -f "$uploadFile" ]]; then
          local result=$($cwd/scripts/mc cp "$uploadFile" minio/$4)
          echo "http://$server:${port}/$4/$2$3"
      else
          echo "Error: File $uploadFile does not exist!"
      fi
    }
    # Helper
    check_error () {
        if [[ "$1" == Error* ]]; then
            echo "$1"
            exit 1
        fi
    }

    for tempfile in $(find "$inputFolder" -name "*.mp4" | sort | uniq -u) ; do
        tempfilename=$(basename $tempfile)
        uuid="${tempfilename%.*}"
        echo "Publishing $inputFolder/$tempfilename"
        # Publish video
        urlVideo=$(minio_upload "$inputFolder" $uuid ".mp4" $bucket)
        check_error "$urlVideo"
        # Publish audio
        urlAudio=$(minio_upload "$inputFolder" $uuid ".wav" $bucket)
        check_error "$urlAudio"
        # Publish asr result
        urlAsrResult=$(minio_upload "$inputFolder" $uuid ".json" $bucket)
        check_error "$urlAsrResult"
        # Publish transcript html file for annotation
        urlTranscript=$(minio_upload "$inputFolder" $uuid ".html" $bucket)
        check_error "$urlTranscript"
        # Create final annotation task JSON configuration file
        JSON_STRING="$(<"$metadataFile")"
        JSON_STRING="${JSON_STRING%\}}"  # remove closing bracket } at end of json string
        videoFileName=$(basename "$videoFile")
        JSON_STRING+=',"originalVideo":"'"$videoFileName"'","title":"'"$videoTitle"'","video":"'"$urlVideo"'","audio":"'"$urlAudio"'","transcript":"'"$urlTranscript"'","asrResult":"'"$urlAsrResult"'"'
        if [[ $inputFolder == *"splitted"* ]]; then
            # splitted folder is part of input folder path -> processing of splitted files -> add interval and index
            uuidArr=(${uuid//_/ })
            index=${uuidArr[1]}
            intervalStr=${uuidArr[2]}
            intervalArrStr="[$(echo "$intervalStr" | tr - ,)]"
            JSON_STRING+=',"splitIndex":"'"$index"'","interval":'"$intervalArrStr"''
        fi
        JSON_STRING+='}'
        echo "$JSON_STRING" > "$inputFolder/$uuid.task.json"
        echo "New annotation task config: $inputFolder/$uuid.task.json"
        echo "Publishing annotation task config: $inputFolder/$uuid.task.json"
        # Publish annotation task json file on minio
        urlTask=$(minio_upload "$inputFolder" $uuid ".task.json" $bucket_tasks)
        check_error "$urlTask"
        # Upload annotation task json file to labelstud.io
        curl -H 'Authorization: Token a9cpk42gv748hzs' \
        -X POST "http://localhost:8083/api/projects/$projectId/import" -F "file=@$inputFolder/$uuid.task.json"
        echo ""
        echo ""
        echo "Annotation task $uuid.task.json published! Url: $urlTask"
    done
    exit $?
fi
