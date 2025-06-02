"""
Receive project id from labelstud.io from project title
"""

import sys
import requests


# TODO Static project id and auth token!
labelstudio_auth_header = {"Authorization" : "Token a9cpk42gv748hzs", "Content-Type": "application/json", "Accept": "application/json"}

options = sys.argv
x = len(options)

if x < 1:
    print("Error: Not enough parameters!")
    print("Usage:")
    print("  python3 get_project_id_for_project_title.py <project-title>")
    print("Example:")
    print("  python3 get_project_id_for_project_title.py 'HAnS Video Snippets'")
else:
    project_title = options[1]
    response_projects_list = requests.get("http://localhost:8083/api/projects", headers=labelstudio_auth_header)
    data = response_projects_list.json()
    task_results = data["results"]
    for item in task_results:
        if item['title'].lower() == project_title.lower():
            print (str(item['id']))
