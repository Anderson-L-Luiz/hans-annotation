"""
Get list of project info items
"""

import json
import argparse


def parse_args() -> argparse.Namespace:
    """
    Parse command line arguments
    """
    parser = argparse.ArgumentParser()
    parser.add_argument("-i", "--info", default="title", type=str, help="JSON info entry to obtain, e.g. title of the project")
    parser.add_argument("-p", "--projects-file", default="projects/projects.json", type=str, help="JSON file containing project definitions")
    parser.add_argument("-w", "--webhooks-only", default=False, type=bool, help="Only select project titles where webhooks are configured")
    return parser.parse_args()


def get_info_from_entry(info, entry):
    """
    Get requested info item value
    """
    if info == "title":
        return str(entry["project"]["title"])
    elif info == "id":
        return str(entry["id"])
    return ""


def main():
    """
    Get list of project info items
    """
    args = parse_args()
    in_file = open(args.projects_file, mode="r", encoding="utf-8")
    data = json.load(in_file)
    info_items = []
    for entry in data["projects"]:
        if args.webhooks_only is True:
            if len(entry["webhooks"]) > 0:
                info_items.append(get_info_from_entry(args.info, entry))
        else:
            info_items.append(get_info_from_entry(args.info, entry))
    print(",".join(info_items))


if __name__ == "__main__":
    main()
