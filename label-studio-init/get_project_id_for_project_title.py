"""
Receive project id from labelstud.io from project title
"""

import sys
import json
import requests
from requests.auth import HTTPBasicAuth


# TODO Static project id and auth token!
labelstudio_auth_header = {"Authorization" : "Token ___AUTH_TOKEN___", "Content-Type": "application/json", "Accept": "application/json"}

options = sys.argv
x = len(options)

if x < 4:
    print("Error: Not enough parameters!")
    print("Usage:")
    print("  python3 get_project_id_for_project_title.py <server> <port> <token> <project-title>")
    print("Example:")
    print("  python3 get_project_id_for_project_title.py 'app' '8080' '23476712340dkj8eafrhrfsde' 'HAnS Video Snippets'")
else:
    server_name = options[1]
    server_port = options[2]
    auth_token = options[3]
    project_title = options[4]
    labelstudio_auth_header["Authorization"] = "Token " + auth_token
    response_projects_list = requests.get("http://" + server_name + ":" + server_port + "/api/projects", headers=labelstudio_auth_header)
    data = response_projects_list.json()
    task_results = data["results"]
    for item in task_results:
        if item['title'].lower() == project_title.lower():
            print (str(item['id']))
