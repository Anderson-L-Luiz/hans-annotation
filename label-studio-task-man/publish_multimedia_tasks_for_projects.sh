#!/bin/bash

showHelp=0
publish=0
inputFolder="."
projectIds="2"
addSlideUrl=0
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

while getopts hi:s:p:f:t:m:sa:v flag
do
    case "${flag}" in
        h) showHelp=1;;
        i) publish=1; inputFolder=$OPTARG;;
        p) projectIds=$OPTARG;;
        f) videoFile=$OPTARG;;
        t) videoTitle=$OPTARG;;
        m) metadataFile=$OPTARG;;
        s) protocol=https;secure=1;;
        a) addSlideUrl=$OPTARG;;
        v) verbose=1;;
        \?) echo "Invalid option: -$OPTARG" >&2; exit 1;;
        :) echo "Option -$OPTARG requires an argument." >&2; exit 1;;
    esac
done

if [[ $showHelp -eq 1 ]] || [[ $publish -eq 0 ]]
then
    echo "Publish all files and import annotation task"
    echo "Usage:"
    echo "  publish_multimedia_tasks.sh -i <input-folder> -p <project-id1,project-id2> [-s <hostname>] -f <input-file> -t <title> -m <meta-data-file> [-v]"
    echo "Parameters: "
    echo "  -i: The input file folder"
    echo "  -p: Annotation project ids, separated with comma, e.g. '2,5,3', or single id, e.g. '4'"
    echo "  -f: Video file"
    echo "  -t: Title of the video"
    echo "  -m: File containing metadata"
    echo "  -a: Set -a 1 to add corresponding slide urls to task json files"
    echo "  -v: Verbose output"
    echo "Example:"
    echo "  publish_multimedia_tasks.sh -i temp -p 2,5 -f file.mp4 -t 'Video Title' -m meta.json -a 1"
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

    # Determine file ending to search for and variable name for annotation task json
    if [[ $inputFolder == */video* ]]; then
        filePattern="*.mp4"
        mediaKey="video"
    elif [[ $inputFolder == */slide* ]]; then
        # filePattern="*.{png,jpg,jpeg}"
        filePattern="*.png"
        mediaKey="slide"
    elif [[ $inputFolder == */audio* ]]; then
        filePattern="*.wav"
        mediaKey="audio"
    else
        echo "Error: inputFolder does not start with 'video', 'slide', or 'audio'."
        exit 1
    fi

    for tempfile in $(find "$inputFolder" -name $filePattern | sort | uniq -u) ; do
        echo "----------------------------> Publish file $tempfile"
        # Publish media file
        tempfilename=$(basename $tempfile)
        uuid="${tempfilename%.*}"
        start=`date +%s.%N`
        fileExtension=".${tempfile##*.}"
        urlMediafile=$(minio_upload "$inputFolder" $uuid $fileExtension $bucket)
        check_error "$urlMediafile"
        end=`date +%s.%N`
        runtime=$( echo "$end - $start" | bc -l )
        echo "Published media file: $runtime s"

        # Create final annotation task JSON configuration file
        echo $metadataFile
        JSON_STRING="$(<"$metadataFile")"
        JSON_STRING="${JSON_STRING%\}}"  # remove closing bracket } at end of json string
        videoFileName=$(basename "$videoFile")
        JSON_STRING+=',"originalVideo":"'"$videoFileName"'","title":"'"$videoTitle"'","'"$mediaKey"'":"'"$urlMediafile"'"'

        # Also add index and interval of media item cut
        if [[ $inputFolder == */slide* ]]; then
            uuidArr=(${uuid//_/ })
            index=${uuidArr[1]}
            time=${uuidArr[2]}
            JSON_STRING+=',"splitIndex":"'"$index"'","time_in_ms":'"$time"''
        else
            uuidArr=(${uuid//_/ })
            baseUuid=${uuidArr[0]}
            index=${uuidArr[1]}
            intervalStr=${uuidArr[2]}
            intervalArrStr="[$(echo "$intervalStr" | tr - ,)]"
            JSON_STRING+=',"splitIndex":"'"$index"'","interval_in_ms":'"$intervalArrStr"''
            # Add slide url in addition to audio/video if needed
            if [[ $addSlideUrl -eq 1 ]]; then
                intervalArr=(${intervalStr//-/ })
                start=${intervalArr[0]}
                urlNameSlide="${baseUuid}_${index}_${start}.png"
                urlSlide="s3://$bucket/$urlNameSlide"  # s3://$4/$2$3
                JSON_STRING+=',"slide":"'"$urlSlide"'"'
            fi
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

        # Iterate over the project IDs provided and add the task to the projects
        IFS=',' read -r -a values_array <<< "$projectIds"
        for projectId in "${values_array[@]}"; do
            curl -H "Authorization: Token $LABEL_STUDIO_USER_TOKEN" \
            -X POST "http://app:$port/api/projects/$projectId/import" -F "file=@$inputFolder/$uuid.task.json"
        done

        end=`date +%s.%N`
        runtime=$( echo "$end - $start" | bc -l )
        echo "Published annotation task:"
        echo "Annotation task $uuid.task.json published! Url: $urlTask, time: $runtime s"
    done
    exit $?
fi
