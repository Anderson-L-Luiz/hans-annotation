#!/bin/bash

# Parameters
videoFolder=""
showHelp=0
videoFile=""
videoTitle=""
metadataFile=""
snippetTemplate="standard"
warmupId=""
secure=0

while getopts i:f:t:m:p:sw:h flag
do
    case "${flag}" in
        i) videoFolder=$OPTARG;;
        f) videoFile=$OPTARG;;
        t) videoTitle=$OPTARG;;
        m) metadataFile=$OPTARG;;
        p) snippetTemplate=$OPTARG;;
        s) secure=1;;
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
    echo "  -t: Title of the video"
    echo "  -m: File containing metadata"
    echo "  -p: Template alias for video snippets project, default: 'standard', values: 'standard', 'science', 'warmup'"
    echo "  -w: Warmup ID to publish tasks to, only used if template alias (-p) is 'warmup', values: '01', '02', '03', '04'"
    echo "Example:"
    echo '  publish_annotation_task.cmd -i Sintel.test_5a171cb8-665e-4840-a2db-97527731394d -f example-files/sintel/videos/Sintel.test.mp4 -t "Sintel Trailer" -m example-files/sintel/label.meta.json -p science'
else
    # Publish to default video_annotation project on labelstud.io
    if [[ $snippetTemplate != "warmup" ]]
    then
        projectId=$(python3 ./get_project_id_for_project_title.py -t "$LABEL_STUDIO_USER_TOKEN" -p "HAnS Video Annotation")
        if [[ $secure -eq 1 ]];
        then
            ./publish.sh -i "$videoFolder" -p "$projectId" -f "$videoFile" -t "$videoTitle" -m "$metadataFile" -s
        else
            ./publish.sh -i "$videoFolder" -p "$projectId" -f "$videoFile" -t "$videoTitle" -m "$metadataFile"
        fi
    fi

    # Publish to default video_snippets project on labelstud.io
    if [[ $snippetTemplate == "standard" ]]
    then
        projectIdSnippets=$(python3 ./get_project_id_for_project_title.py -t "$LABEL_STUDIO_USER_TOKEN" -p "HAnS Video Snippets")
    elif [[ $snippetTemplate == "warmup" ]]
    then
        projectIdSnippets=$(python3 ./get_project_id_for_project_title.py -t "$LABEL_STUDIO_USER_TOKEN" -p "HAnS Video Snippets WarmUp $warmupId")
    elif [[ $snippetTemplate == "science" ]]
    then
        if [[ $warmupId == "" ]]
        then
            projectIdSnippets=$(python3 ./get_project_id_for_project_title.py -t "$LABEL_STUDIO_USER_TOKEN" -p "HAnS Video Snippets - Science")
        else
            projectIdSnippets=$(python3 ./get_project_id_for_project_title.py -t "$LABEL_STUDIO_USER_TOKEN" -p "HAnS Video Snippets - Science $warmupId")
        fi
    fi
    if [[ $secure -eq 1 ]];
    then
        ./publish.sh -i "$videoFolder/splitted" -p "$projectIdSnippets" -f "$videoFile" -t "$videoTitle" -m "$metadataFile" -s
    else
        ./publish.sh -i "$videoFolder/splitted" -p "$projectIdSnippets" -f "$videoFile" -t "$videoTitle" -m "$metadataFile"
    fi
fi
