: # Configures hans-ext-annotation
:<<"::CMDLITERAL"
@ECHO OFF
GOTO :CMDSCRIPT
::CMDLITERAL
#!/bin/bash

flagEnableSignup=0

while getopts e flag
do
    case "${flag}" in
        e) flagEnableSignup=1;;
    esac
done

echo "Applying configuration"

: # Configure label-studio and docker compose
echo "LABEL_STUDIO_HOST=localhost:8080" > .env
echo "COMPOSE_PROJECT_NAME=hans-ext-annotation" >> .env

: # Configure user and group for execution
: # export UID=$(id -u)
echo "UID=$(id -u)" >> .env
export GID=$(id -g)
echo "GID=$(id -g)" >> .env

: # postgresql connection
: # Workaround for Apple Silicon bug in postgresql connection
: # https://stackoverflow.com/questions/62807717/how-can-i-solve-postgresql-scram-authentifcation-problem
if [[ $(uname -p) = "arm64" ]] || [[ $(uname -p) = "arm" ]]
then
    export POSTGRESQL_VERSION=13
    echo "POSTGRESQL_VERSION=13" >> .env
else
    export POSTGRESQL_VERSION=14
    echo "POSTGRESQL_VERSION=14" >> .env
fi

if [[ $flagEnableSignup -eq 1 ]]
then
    echo "LABEL_STUDIO_DISABLE_SIGNUP_WITHOUT_LINK=false" >> .env
fi

: # Configure uploader (not fully working yet)
echo "Installing config.json to experimental/importer/vue/src/config/config.json"
cp config.json experimental/importer/vue/src/config/config.json
echo "Done"
exit $?

:CMDSCRIPT
ECHO Windows is currently not supported
