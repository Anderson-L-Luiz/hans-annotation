#!/bin/bash

# Parameters
videoFolder=""
showHelp=0
videoFile=""
videoTitle=""
metadataFile=""
secure=0

while getopts i:f:t:m:sh flag
do
    case "${flag}" in
        i) videoFolder=$OPTARG;;
        f) videoFile=$OPTARG;;
        t) videoTitle=$OPTARG;;
        m) metadataFile=$OPTARG;;
        s) secure=1;;
        h) showHelp=1;;
    esac
done

if [[ $showHelp -eq 1 ]] || [[ $videoFolder = "" ]];
then
    echo "Publish already prepared videos and slides data on the labelstud.io instance"
    echo "Usage:"
    echo "  publish_multimedia_tasks.cmd -i <snippet-folder> -f <video-file> [-s <server-hostname>] -t <video-title> -m <meta-data-file>"
    echo "Parameters: "
    echo "  -i: Folder containing snippets generated with `create_multimedia_annotation_tasks.sh`"
    echo "  -f: File of the original video"
    echo "  -t: Title of the video"
    echo "  -m: File containing metadata"
    echo "Example:"
    echo '  publish_multimedia_tasks.sh -i Sintel.test_5a171cb8-665e-4840-a2db-97527731394d -f example-files/sintel/videos/Sintel.test.mp4 -t "Sintel Trailer" -m example-files/sintel/label.meta.json'
else
    # Upload data for projects requiring only slides
    projectId1=$(python3 ./get_project_id_for_project_title.py -t "$LABEL_STUDIO_USER_TOKEN" -p "Mayer: visuelle Signalisierung")
    projectId2=$(python3 ./get_project_id_for_project_title.py -t "$LABEL_STUDIO_USER_TOKEN" -p "Mayer: räumliche Kontiguität")
    if [[ $secure -eq 1 ]];
    then
        ./publish_multimedia_tasks_for_projects.sh -i "$videoFolder/slides" -p "$projectId1","$projectId2" -f "$videoFile" -t "$videoTitle" -m "$metadataFile" -s
    else
        ./publish_multimedia_tasks_for_projects.sh -i "$videoFolder/slides" -p "$projectId1","$projectId2" -f "$videoFile" -t "$videoTitle" -m "$metadataFile"
    fi

    # Upload data for project requiring video around slide change
    projectId=$(python3 ./get_project_id_for_project_title.py -t "$LABEL_STUDIO_USER_TOKEN" -p "Mayer: zeitliche Kontiguität")
    if [[ $secure -eq 1 ]];
    then
        ./publish_multimedia_tasks_for_projects.sh -i "$videoFolder/video_split_around_changes" -p "$projectId" -f "$videoFile" -t "$videoTitle" -m "$metadataFile" -s
    else
        ./publish_multimedia_tasks_for_projects.sh -i "$videoFolder/video_split_around_changes" -p "$projectId" -f "$videoFile" -t "$videoTitle" -m "$metadataFile"
    fi

    # Upload data for project requiring fixed audio blocks of 30s
    projectId1=$(python3 ./get_project_id_for_project_title.py -t "$LABEL_STUDIO_USER_TOKEN" -p "Mayer: Stimme")
    projectId2=$(python3 ./get_project_id_for_project_title.py -t "$LABEL_STUDIO_USER_TOKEN" -p "Mayer: Personalisierung")
    if [[ $secure -eq 1 ]];
    then
        ./publish_multimedia_tasks_for_projects.sh -i "$videoFolder/audio_split_fixed" -p "$projectId1","$projectId2" -f "$videoFile" -t "$videoTitle" -m "$metadataFile" -s
    else
        ./publish_multimedia_tasks_for_projects.sh -i "$videoFolder/audio_split_fixed" -p "$projectId1","$projectId2" -f "$videoFile" -t "$videoTitle" -m "$metadataFile"
    fi

    # Upload data for projects requiring audio and slides (or video split on slide changes)
    projectId1=$(python3 ./get_project_id_for_project_title.py -t "$LABEL_STUDIO_USER_TOKEN" -p "Mayer: Kohärenz")
    projectId2=$(python3 ./get_project_id_for_project_title.py -t "$LABEL_STUDIO_USER_TOKEN" -p "Mayer: Redundanz Modalität")
    projectId3=$(python3 ./get_project_id_for_project_title.py -t "$LABEL_STUDIO_USER_TOKEN" -p "Mayer: verbale Signalisierung")
    if [[ $secure -eq 1 ]];
    then
        ./publish_multimedia_tasks_for_projects.sh -i "$videoFolder/audio_split_on_changes" -p "$projectId1","$projectId2","$projectId3" -f "$videoFile" -t "$videoTitle" -m "$metadataFile" -a 1 -s
    else
        ./publish_multimedia_tasks_for_projects.sh -i "$videoFolder/audio_split_on_changes" -p "$projectId1","$projectId2","$projectId3" -f "$videoFile" -t "$videoTitle" -m "$metadataFile" -a 1
    fi
fi
