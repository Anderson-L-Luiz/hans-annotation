"""
Convert a mod9 word level ASR result our ASR result structure
"""
import argparse
from utils import read_file, write_to_file, load_json, dump_json


def parse_args() -> argparse.Namespace:
    """
    Parse command line arguments
    """
    parser = argparse.ArgumentParser()
    parser.add_argument("-i", "--input-file", default="uuid.wav.word.json", type=str, help="Input file mod9 word level ASR json result")
    parser.add_argument("-l", "--language", default="en", type=str, help="Language used for the model to create the whisper word level ASR result json file")
    parser.add_argument("-o", "--output-file", default="uuid.json", type=str, help="Output file for converted ASR json result")
    return parser.parse_args()


def main():
    """
    Convert a whisper word level ASR result our ASR result structure
    """
    args = parse_args()
    lines_mod9_data = read_file(args.input_file)
    meta_data = load_json(lines_mod9_data[0])

    asr_result = {}
    asr_result["result"] = []
    asr_result["meta"] = {
        "model": {
            "name": meta_data["asr_model"],
            "language": args.language
        },
        "engine": {
            "name": "mod9",
            "version": meta_data["engine"]["version"]
        }
    }
    word_count = 0
    valid_entries = len(lines_mod9_data) -1
    for index in range(1, valid_entries):
        asr_data = load_json(lines_mod9_data[index])
        if asr_data["status"] != "completed":
            segment = {}
            segment["interval"] = asr_data["interval"]
            segment["transcript"] = asr_data["transcript"].lstrip()
            segment["result_index"] = asr_data["result_index"]
            # asr overall segment confidence not available
            #segment["confidence"] = asr_data["confidence"]
            segment["words"] = []
            for word in asr_data["words"]:
                curr_word = {}
                curr_word["interval"] = word["interval"]
                curr_word["word"] = word["word"]
                curr_word["word_index"] = word_count
                curr_word["confidence"] = word["confidence"]
                segment["words"].append(curr_word)
                word_count = word_count + 1
            asr_result["result"].append(segment)

    write_to_file(args.output_file, dump_json(asr_result))


if __name__ == "__main__":
    main()
