: # Stops and removes the built hans-ext-annotation
:<<"::CMDLITERAL"
@ECHO OFF
GOTO :CMDSCRIPT
::CMDLITERAL
#!/bin/bash

flagRemove=0

while getopts r flag
do
    case "${flag}" in
        r) flagRemove=1;;
    esac
done

: # Config
./config.cmd

: # Stop and remove previous container
if [[ $flagRemove -eq 1 ]]
then
    echo "Docker Compose Down And Remove ext-annotation"
    docker compose down --rmi all -v
else
    echo "Docker Compose Stop ext-annotation"
    docker compose stop
fi

if [[ $flagRemove -eq 1 ]]
then
    echo "WARNING! This will remove:"
    echo "  - all stored labelstud.io data"
    echo "  - all stored annotation data"
    echo "  - labelstud.io postgresql database"
    echo ""
    read -r -p "Are you sure you want to continue? [y/N] " response
    response=${response:l}
    if [[ $response =~ ^(yes|y| ) ]] || [[ -z $response ]]; then
        rm -rf label-studio-data
        rm -rf annotation-data
        rm -rf postgresql-data
    fi
    docker system prune -a
    docker volume prune
    docker network prune
fi
exit $?

:CMDSCRIPT
ECHO Windows is currently not supported
