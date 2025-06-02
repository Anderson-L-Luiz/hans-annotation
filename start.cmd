: # Builds and runs the hans-ext-annotation
:<<"::CMDLITERAL"
@ECHO OFF
GOTO :CMDSCRIPT
::CMDLITERAL
#!/bin/bash

flagBuild=0
flagEnableSignup=0
flagExperiment=0

while getopts bex flag
do
    case "${flag}" in
        b) flagBuild=1;;
        e) flagEnableSignup=1;;
        x) experiment=1;;
    esac
done

: # Stop and remove previous containers
./stop.cmd

: # Configure docker command depending on flags
docker_cmd="docker compose -f docker-compose.yaml"
if [[ $flagExperiment -eq 1 ]]
then
    echo "Build with experimental features"
    docker_cmd="$docker_cmd -f docker-compose.exp.yaml"
fi

if [[ $flagBuild -eq 1 ]]
then
    echo "Docker Compose Up And Build ext-annotation"
    docker_cmd="$docker_cmd up --force-recreate --build --always-recreate-deps -d"
else
    echo "Docker Compose Up ext-annotation"
    docker_cmd="$docker_cmd up -d"
fi

: # Config signup
if [[ $flagEnableSignup -eq 1 ]]
then
    ./config.cmd -e
else
    ./config.cmd
fi

: # Create label-studio data folder
if [[ ! -d label-studio-data ]]
then
    mkdir label-studio-data
    mkdir label-studio-data/config
    mkdir label-studio-data/export
    mkdir label-studio-data/media
    mkdir label-studio-data/media/upload
    mkdir label-studio-data/media/export
    chmod -R 777 label-studio-data/
fi

: # Create postgresql data folder
if [[ ! -d postgresql-data ]]
then
    mkdir postgresql-data
    chmod -R 777 postgresql-data/
fi

: # Create annotation data folder
if [[ ! -d annotation-data ]]
then
    mkdir annotation-data
    chmod -R 777 annotation-data/
fi

: # Install annotation templates for template projects
templateProjects=$(python3 ./label-studio-init/get_project_info.py --info "title" --projects-file "./label-studio-init/projects/projects.json")
IFS=',' read -r -a templateProjectsArray <<< "$templateProjects"
for templateProjectName in "${templateProjectsArray[@]}"; do
  filePath="label-studio-data/config/${templateProjectName}.xml"
  echo "$(python3 ./label-studio-init/create_project_config.py --project-name "$templateProjectName" --format xml)" > "$filePath"
done

: # Build and run backend
$docker_cmd
exit $?

:CMDSCRIPT
ECHO Windows is currently not supported
