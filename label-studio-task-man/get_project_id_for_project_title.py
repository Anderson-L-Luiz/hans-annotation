"""
Receive project id from labelstud.io from project title
"""

import argparse
import requests

def parse_args() -> argparse.Namespace:
    """
    Parse command line arguments
    """
    parser = argparse.ArgumentParser()
    parser.add_argument("-t", "--token", default="", type=str, help="Labelstud.io auth token")
    parser.add_argument("-p", "--project-title", default="HAnS Video Snippets", type=str, help="Project title")
    return parser.parse_args()


def main():
    """
    Print project id to console
    """
    args = parse_args()
    labelstudio_auth_header = {"Authorization" : "Token " + args.token, "Content-Type": "application/json", "Accept": "application/json"}
    response_projects_list = requests.get("http://10.50.1.41:8083/api/projects", headers=labelstudio_auth_header)
    data = response_projects_list.json()
    task_results = data["results"]
    for item in task_results:
        if item['title'].lower() == args.project_title.lower():
            print (str(item['id']))


if __name__ == "__main__":
    main()
