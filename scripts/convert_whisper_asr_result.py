"""
Convert a whisper word level ASR result our ASR result structure
"""
import argparse
from utils import read_json_file, write_to_file, dump_json


def parse_args() -> argparse.Namespace:
    """
    Parse command line arguments
    """
    parser = argparse.ArgumentParser()
    parser.add_argument("-i", "--input-file", default="uuid.wav.word.json", type=str, help="Input file whisper word level ASR json result")
    parser.add_argument("-m", "--model", default="large-v2", type=str, help="Model used to create the whisper word level ASR result json file")
    parser.add_argument("-l", "--language", default="en", type=str, help="Language used for the model to create the whisper word level ASR result json file")
    parser.add_argument("-v", "--version", default="0815", type=str, help="Whisper package version")
    parser.add_argument("-t", "--version-timestamped", default="0815", type=str, help="Whisper timestamped package version")
    parser.add_argument("-o", "--output-file", default="uuid.json", type=str, help="Output file for converted ASR json result")
    return parser.parse_args()


def main():
    """
    Convert a whisper word level ASR result our ASR result structure
    """
    args = parse_args()
    whisper_data = read_json_file(args.input_file)
    asr_result = {}
    asr_result["result"] = []
    asr_result["meta"] = {
        "model": {
            "model": args.model,
            "language": args.language            
        },
        "engine": {
            "name": "whisper",
            "version": args.version,
            "version-timestamped": args.version_timestamped
        }
    }
    word_count = 0

    for item in whisper_data["segments"]:
        segment = {}
        segment["interval"] = [item["start"], item["end"]]
        segment["transcript"] = item["text"].lstrip()
        segment["result_index"] = item["id"]
        segment["confidence"] = item["confidence"]
        segment["words"] = []
        for word in item["words"]:
            curr_word = {}
            curr_word["interval"] = [word["start"], word["end"]]
            curr_word["word"] = word["text"]
            curr_word["word_index"] = word_count
            curr_word["confidence"] = word["confidence"]
            segment["words"].append(curr_word)
            word_count = word_count + 1
        asr_result["result"].append(segment)

    write_to_file(args.output_file, dump_json(asr_result))


if __name__ == "__main__":
    main()
