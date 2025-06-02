#!/bin/bash

port=8080
showHelp=0

while getopts p:h flag
do
    case "${flag}" in
        p) port=$OPTARG;;
        h) showHelp=1;;
    esac
done

if [[ $showHelp -eq 1 ]]
then
    echo "Initializes label studio app"
    echo "Usage:"
    echo "  init.sh -p <label-studio-app-port>"
    echo "Parameters: "
    echo "  -p: The label studio app port"
    echo "Example:"
    echo "  init.sh -p 8080"
else
    echo "Waiting for labelstud.io"
    while ! nc -z app $port; do
      sleep 0.1
    done

    orgs=$(curl -X GET -H "Authorization: Token $LABEL_STUDIO_USER_TOKEN" http://app:$port/api/organizations/)
    # echo "labelstud.io organizations: $orgs"

    projectsResponse=$(curl -X GET -H "Authorization: Token $LABEL_STUDIO_USER_TOKEN" http://app:$port/api/projects/)
    echo "labelstud.io projects: $projectsResponse"

    webhooksResponse=$(curl -X GET -H "Authorization: Token $LABEL_STUDIO_USER_TOKEN" http://app:$port/api/webhooks/)
    echo "labelstud.io webhooks: $webhooksResponse"

    echo "Initializing labelstud.io projects on port $port with token $LABEL_STUDIO_USER_TOKEN"

    templateProjects=$(python3 ./get_project_info.py --info title --projects-file ./projects/projects.json)
    IFS=',' read -r -a templateProjectsArray <<< "$templateProjects"

    templateProjectsWithWebhook=$(python3 ./get_project_info.py --info title --projects-file ./projects/projects.json --webhooks-only True)
    IFS=',' read -r -a templateProjectsWithWebhookArray <<< "$templateProjectsWithWebhook"

    cd projects
    # Adding template projects based on template
    for templateProjectName in "${templateProjectsArray[@]}"; do
      if [[ ! $projectsResponse == *"\"title\":\"$templateProjectName\""* ]]; then
        echo "Adding project: $templateProjectName"
        projectConfig="$(python3 ./../create_project_config.py --project-name "$templateProjectName" --format json)"
        response=$(curl -X POST -H 'Content-Type:application/json' -H "Authorization: Token $LABEL_STUDIO_USER_TOKEN" -H "Accept:application/json" -d "$projectConfig" http://app:$port/api/projects/)
        echo "Added project: $templateProjectName"
      else
        echo "Project '$templateProjectName' already added - skipping"
      fi
      # Adding template projects webhook if configured
      if printf '%s\0' "${templateProjectsWithWebhookArray[@]}" | grep -Fxqz -- "$templateProjectName"; then
        if [[ ! $webhooksResponse == *"/$templateProjectName\""* ]]; then
          projectIdWithWebhook=$(python3 ./../get_project_id_for_project_title.py "app" "$port" "$LABEL_STUDIO_USER_TOKEN" "$templateProjectName")
          webhookConfig="$(python3 ./../create_webhook_config.py --project-name "$templateProjectName" --project-id "$projectIdWithWebhook")"
          echo "Adding webhook config to project id $projectIdWithWebhook"
          response=$(curl -X POST -H 'Content-Type:application/json' -H "Authorization: Token $LABEL_STUDIO_USER_TOKEN" -H "Accept:application/json" -d "$webhookConfig" http://app:$port/api/webhooks/)
          echo "Added webhook: $webhookConfig"
        else
          echo "Skipping webhook for project $templateProjectName: Webhook already added to labelstud.io!"
        fi
      fi
    done
    cd ..
    exit $?
fi
