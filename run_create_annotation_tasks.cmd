: # Create annotation tasks for all videos contained in an upload-bundle folder on the labelstud.io instance
:<<"::CMDLITERAL"
@ECHO OFF
GOTO :CMDSCRIPT
::CMDLITERAL
#!/bin/bash

#set -x
set -e

lectureFolder=""
language="de"
server="localhost"
projectAlias="science"
showHelp=0
: # Engine 'mod9' or 'whisper'
engine="mod9"

while getopts e:hi:l:p:s: flag
do
    case "${flag}" in
        e) engine=$OPTARG;;
        h) showHelp=1;;
        i) lectureFolder=$OPTARG;;
        l) language=$OPTARG;;
        p) projectAlias=$OPTARG;;
        s) server=$OPTARG;;
    esac
done

if [[ $showHelp -eq 1 ]];
then
    echo "Create annotation tasks for all videos contained in an upload-bundle folder on the labelstud.io instance"
    echo "Usage:"
    echo "  run_create_annotation_tasks.cmd -i <input-folder> -l <language> -t <video-title> -m <meta-data-file> [-s <hostname>] [-x <interaval-sec>] -p <project-template-alias> [-w <warmup-id>]"
    echo "Parameters: "
    echo "  -i: Input folder containing 'label.meta.json' and subfolder 'videos' with video files"
    echo "  -l: Language of the video file, default: 'de', values: 'en', 'de'"
    echo "  -p: Template alias for video snippets project, default: 'science', values: 'standard', 'science'"
    echo "  -s: Server hostname, default: 'localhost'"
    echo "Example:"
    echo '  run_create_annotation_tasks.cmd -i example-files/sintel -l en -p science -s localhost'
else
    lectureVideos="$lectureFolder/videos"
    for videofile in $(find "$lectureVideos" -name "*.mp4" | sort | uniq -u) ; do
        videofileNameWithExt=$(basename $videofile)
        videofileName="${videofileNameWithExt%.*}"
        ./create_annotation_task.cmd -s "$server" -f "$videofile" -e "$engine" -l "$language" -t "$videofileName" -m "$lectureFolder/label.meta.json" -p "$projectAlias"
        if [[ $? -gt 0 ]]
        then
            echo "Unexpected error during create_annotation_task.cmd for $videofileName occured!"
            exit 1
        fi
    done
    echo "Finished processing $lectureFolder!"
fi
exit $?

:CMDSCRIPT
ECHO Windows is currently not supported
