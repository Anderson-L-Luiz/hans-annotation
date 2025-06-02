"""
Get version of a python package
"""
import argparse
from importlib.metadata import version


def parse_args() -> argparse.Namespace:
    """
    Parse command line arguments
    """
    parser = argparse.ArgumentParser()
    parser.add_argument("-p", "--package", default="openai-whisper", type=str, help="Name of the python package")
    return parser.parse_args()


def main():
    """
    Print version of python package to console
    """
    args = parse_args()
    print(version(args.package))


if __name__ == "__main__":
    main()
