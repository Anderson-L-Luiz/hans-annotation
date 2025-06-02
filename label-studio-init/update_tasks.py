"""
Update labelstud.io tasks
"""

import argparse
import json
import re
import requests


def parse_args() -> argparse.Namespace:
    """
    Parse command line arguments
    """
    parser = argparse.ArgumentParser()
    parser.add_argument("-b", "--begin", type=int, help="First task id to update")
    parser.add_argument("-e", "--end", type=int, help="Last task id to update")
    parser.add_argument("-m", "--meta-file", type=str, help="Meta data file for update")
    parser.add_argument("-s", "--server", type=str, help="Server hostname of the label studio app")
    parser.add_argument("-p", "--port", type=str, help="Port of the label studio app")
    parser.add_argument("-t", "--token", type=str, help="Token for authorization")
    parser.add_argument("-v", "--video-task-type", default="snippet", type=str,
        help="Video file type for each task, default='snippet', values: 'snippet', 'standard'; "
        + "Interval and split index will be added if 'snippet' is active!")
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


def get_task_url(task_id, server, port):
    """
    Get task url
    """
    return "http://" + server + ":" + str(port) + "/api/tasks/" + str(task_id) + "/"


def get_task_data(task_id, server, port, token):
    """
    Get json task data for a specfic task using task id
    """
    response = requests.get(
        url=get_task_url(task_id, server, port), headers={'Authorization': f'Token {token}'})
    return response.json()


def patch_task_data(task_id, server, port, token, task_data):
    """
    Patch task with json task data
    """
    final_task_data = {
        "id": int(task_data["id"]),
        "data": dump_json(task_data["data"]),
        "meta": dump_json(task_data["meta"]),
        "is_labeled": task_data["is_labeled"],
        "overlap": task_data["overlap"],
        "inner_id": task_data["inner_id"],
        "total_annotations": task_data["total_annotations"],
        "cancelled_annotations": task_data["cancelled_annotations"],
        "total_predictions": task_data["total_predictions"],
        "comment_count": int(task_data["comment_count"]),
        "unresolved_comment_count": task_data["unresolved_comment_count"],
        "last_comment_updated_at": task_data["last_comment_updated_at"],
        "project": int(task_data["project"])
    }
    #print(f"Patch task data: {dump_json(final_task_data)}")

    response = requests.patch(
        url=get_task_url(task_id, server, port), data=final_task_data, headers={'Authorization': f'Token {token}'})
    return response.json()


def get_interval_and_split_index(file):
    """
    Get interval and split index as json dict
    """
    regex_matches = [
        # Old
        # 83c955fc-2a54-4cf2-bdbc-caca2b60ef5f.000000.0-7.wav
        # 83c955fc-2a54-4cf2-bdbc-caca2b60ef5f.000028.196-203.wav
        # 83c955fc-2a54-4cf2-bdbc-caca2b60ef5f.000498.3486-3493.wav
        r".*[.](?P<split_index>\d{1,})[.](?P<start_interval>\d{1,})[-](?P<end_interval>\d{1,})[.].*",
        # Intermediate and new format
        # a87b4029-224c-46cb-8fdf-88dfe9ae37bf_0_0.0-7.37.wav
        # a87b4029-224c-46cb-8fdf-88dfe9ae37bf_397_2775.05-2781.94.wav
        # a87b4029-224c-46cb-8fdf-88dfe9ae37bf_441_3081.61-3088.45.wav
        # ffd61a81-c4b2-4b89-8b14-6b05038e78bc_00218_1524.87-1531.55.wav
        r".*[_](?P<split_index>\d{1,})[_](?P<start_interval>\d{1,}[.]\d{1,})[-](?P<end_interval>\d{1,}[.]\d{1,})[.].*"
    ]
    for regex_match in regex_matches:
        m = re.match(regex_match, file)
        if m is not None:
            groups = []
            groups.extend(m.groups())
            if len(groups) == 3:
                split_index = int(m.group('split_index'))
                start_interval = float(m.group('start_interval'))
                end_interval = float(m.group('end_interval'))
                data = {
                    "interval": [
                      start_interval,
                      end_interval
                    ],
                    "splitIndex": "{:05d}".format(split_index)
                }
                print(f"New interval and split index: {dump_json(data)}")
                return data


def update_task_data(task_id, video_task_type, server, port, token, meta_data):
    """
    Update existing task with new meta data, new interval and split_index
    """
    try:
        old_task_data = get_task_data(task_id, server, port, token)
        print(f"Task data: {dump_json(old_task_data)}")
        old_task_data["data"].update(meta_data)
        if video_task_type == "snippet":
            old_task_data["data"].update(
                get_interval_and_split_index(old_task_data["data"]["audio"]))
        patched_task_data = patch_task_data(task_id, server, port, token, old_task_data)
        print(f"Patched task data: {dump_json(patched_task_data)}")
    except:
        print(f"Could not update task with id {task_id}, maybe not existing.")


def main():
    """
    Update labelstud.io tasks
    """
    args = parse_args()

    meta_data = read_json_file(args.meta_file)

    if args.begin == args.end:
        update_task_data(
            args.begin, args.video_task_type, args.server, args.port, args.token, meta_data)
    else:
        for task_id in range(args.begin, args.end + 1):
            print("##########")
            update_task_data(
                task_id, args.video_task_type, args.server, args.port, args.token, meta_data)


if __name__ == "__main__":
    main()
