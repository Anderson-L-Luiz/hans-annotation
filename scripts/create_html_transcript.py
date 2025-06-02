"""
Convert a ASR result to html transcript
"""
import argparse
from utils import read_json_file, write_to_file


def parse_args() -> argparse.Namespace:
    """
    Parse command line arguments
    """
    parser = argparse.ArgumentParser()
    parser.add_argument("-i", "--input-file", default="uuid.json", type=str, help="Input file ASR json result")
    parser.add_argument("-o", "--output-file", default="uuid.html", type=str, help="Output file html transcript")
    return parser.parse_args()


def main():
    """
    Convert a ASR result to html transcript
    """
    args = parse_args()
    asr_data = read_json_file(args.input_file)

    html_data = '<div class="asrTranscript">\n'
    html_start_tag = '<div style="float: left; display: flex; border: 1px solid #F2F3F4; background-color: #F8F9F9;border-radius: 5px; padding: 7px; margin: 10px 0;">\n<p class="asrTranscriptContent">\n<b>\n'
    html_interval_end = '</b>\n'
    html_end_transcript_tag = '</p></div>\n'
    
    result = html_data
    for item in asr_data["result"]:
        result += html_start_tag
        result += "Interval [" + str(item["interval"][0]) + "," + str(item["interval"][1]) + "]:\n"
        result += html_interval_end
        result += item["transcript"] + "\n"
        result += html_end_transcript_tag
    result += "</div>\n"

    write_to_file(args.output_file, result)


if __name__ == "__main__":
    main()
