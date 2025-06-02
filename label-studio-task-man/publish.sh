#!/bin/bash

showHelp=0
publish=0
inputFolder="."
projectId="2"
verbose=0
videoFile=""
videoTitle=""
metadataFile=""
secure=0
protocol=http

# label-studio app port
port=8000

# minio configuration
database="annotationdb"
dbport=9003
bucket="assets"
bucket_tasks="tasks"
MINIO_ROOT_USER=$ANNOTATION_DB_ROOT_USER
MINIO_ROOT_PASSWORD=$ANNOTATION_DB_ROOT_PASSWORD

#set -x
set -e

while getopts hi:p:f:t:m:sv flag
do
    case "${flag}" in
        h) showHelp=1;;
        i) publish=1; inputFolder=$OPTARG;;
        p) projectId=$OPTARG;;
        f) videoFile=$OPTARG;;
        t) videoTitle=$OPTARG;;
        m) metadataFile=$OPTARG;;
        s) protocol=https;secure=1;;
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
    echo "  -f: Video file"
    echo "  -t: Title of the video"
    echo "  -m: File containing metadata"
    echo "  -v: Verbose output"
    echo "Example:"
    echo "  publish.sh -i temp/splitted -p 2 -f file.mp4 -t 'Video Title' -m meta.json"
else
    cwd=$(pwd)

    # Initialize minio
    if [[ $secure -eq 1 ]];
    then
        "$cwd/mc" alias set minio $protocol://$database:$dbport $MINIO_ROOT_USER $MINIO_ROOT_PASSWORD --insecure
    else
        "$cwd/mc" alias set minio $protocol://$database:$dbport $MINIO_ROOT_USER $MINIO_ROOT_PASSWORD
    fi

    # Do not: Allow anonymous download on minio bucket
    #"$cwd/mc" anonymous set download minio/$bucket
    #"$cwd/mc" anonymous set download minio/$bucket_tasks

    # Publish video on minio: https://docs.min.io/minio/baremetal/reference/minio-mc/mc-share-download.html
    minio_upload () {
      uploadFile="$1/$2$3"
      if [[ -f "$uploadFile" ]]; then
          local result=$("$cwd/mc" cp "$uploadFile" minio/$4)
          # use s3 protocol, will be replaced with pre signed url during runtime
          echo "s3://$4/$2$3"
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
        echo ""
        echo ""
        echo "Publishing $inputFolder/$tempfilename"
        # Publish video
        start=`date +%s.%N`
        urlVideo=$(minio_upload "$inputFolder" $uuid ".mp4" $bucket)
        check_error "$urlVideo"
        end=`date +%s.%N`
        runtime=$( echo "$end - $start" | bc -l )
        echo "Published video: $runtime s"

        # Publish audio
        start=`date +%s.%N`
        urlAudio=$(minio_upload "$inputFolder" $uuid ".wav" $bucket)
        check_error "$urlAudio"
        end=`date +%s.%N`
        runtime=$( echo "$end - $start" | bc -l )
        echo "Published audio: $runtime s"

        #start=`date +%s.%N`
        #urlAudioFlac=$(minio_upload "$inputFolder" $uuid ".flac" $bucket)
        #check_error "$urlAudio"
        #end=`date +%s.%N`
        #runtime=$( echo "$end - $start" | bc -l )
        #echo "Published flac audio: $runtime s"

        # Publish asr result
        start=`date +%s.%N`
        urlAsrResult=$(minio_upload "$inputFolder" $uuid ".json" $bucket)
        check_error "$urlAsrResult"
        end=`date +%s.%N`
        runtime=$( echo "$end - $start" | bc -l )
        echo "Published asr result: $runtime s"

        # Publish transcript html file for annotation
        start=`date +%s.%N`
        urlTranscript=$(minio_upload "$inputFolder" $uuid ".html" $bucket)
        check_error "$urlTranscript"
        end=`date +%s.%N`
        runtime=$( echo "$end - $start" | bc -l )
        echo "Published transcript: $runtime s"

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
        start=`date +%s.%N`
        urlTask=$(minio_upload "$inputFolder" $uuid ".task.json" $bucket_tasks)
        check_error "$urlTask"
        end=`date +%s.%N`
        runtime=$( echo "$end - $start" | bc -l )
        echo "Published annotation task: $runtime s"

        # Upload annotation task json file to labelstud.io
        start=`date +%s.%N`
        curl -H "Authorization: Token $LABEL_STUDIO_USER_TOKEN" \
        -X POST "http://app:$port/api/projects/$projectId/import" -F "file=@$inputFolder/$uuid.task.json"        
        end=`date +%s.%N`
        runtime=$( echo "$end - $start" | bc -l )
        echo "Published annotation task:"
        echo "Annotation task $uuid.task.json published! Url: $urlTask, time: $runtime s"
    done
    exit $?
fi
