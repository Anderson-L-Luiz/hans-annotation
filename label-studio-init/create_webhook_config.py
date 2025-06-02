"""
Create labelstud.io webhook configuration
"""

import argparse
import json
import sys
import os


def parse_args() -> argparse.Namespace:
    """
    Parse command line arguments
    """
    parser = argparse.ArgumentParser()
    parser.add_argument("-i", "--project-id", type=str, help="Labelstud.io web Project-Id of the project")
    parser.add_argument("-p", "--project-name", type=str, help="Name of the project")
    return parser.parse_args()


def dump_json(data) -> str:
    """
     Dump JSON to str
    """
    return json.dumps(data, indent=2, ensure_ascii=False)


def read_json_file(file):
    """
    Read a json file and return json
    """
    with open(file, mode="r", encoding="utf-8") as in_file:
        return json.load(in_file)


def get_project_titles(projects_data):
    """
    Get list of project titles
    """
    titles = []
    for entry in projects_data["projects"]:
        titles.append(str(entry["project"]["title"]))
    return titles


def get_project_config(projects_data, project_name):
    """
    Get project config from project name
    """
    for entry in projects_data["projects"]:
        if entry["project"]["title"] == project_name:
            return entry


def main():
    """
    Create labelstud.io webhook configuration
    """
    args = parse_args()

    projects_dir = os.path.join(os.path.dirname(os.path.realpath(__file__)), "projects")

    projects_data = read_json_file(os.path.join(projects_dir, "projects.json"))
    project_titles = get_project_titles(projects_data)

    if args.project_name in project_titles:
        project_name = args.project_name
    else:
        print(f"Provided project name '{args.project_name}' not valid - Exit")
        sys.exit()

    project_config = get_project_config(projects_data, project_name)
    webhooks_data = read_json_file(os.path.join(projects_dir, "webhooks.json"))

    for webhook_name in project_config["webhooks"]:
        if webhook_name in webhooks_data:
            my_webhook = webhooks_data[webhook_name]
            my_webhook["project"] = int(args.project_id)
            print(dump_json(my_webhook))
    sys.exit(0)


if __name__ == "__main__":
    main()
