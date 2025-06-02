"""
Utils used by the other python scripts.
"""
import json


def read_file(file):
    """
    Read a json file and return json
    """
    with open(file, mode="r", encoding="utf-8") as in_file:
        return in_file.readlines()


def read_json_file(file):
    """
    Read a json file and return json
    """
    with open(file, mode="r", encoding="utf-8") as in_file:
        return json.load(in_file)


def write_to_file(filename, data, fmode="w"):
    """
    Write data to file
    """
    with open(filename, fmode, encoding="utf-8") as f:
        f.write(data)


def load_json(content):
    """
    Load json content
    """
    return json.loads(content)


def dump_json(data) -> str:
    """
     Dump JSON to str
    """
    return json.dumps(data, indent=2, ensure_ascii=False)
