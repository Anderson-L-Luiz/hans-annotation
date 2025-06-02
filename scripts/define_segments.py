import argparse
import json
import os
from dataclasses import dataclass
from pathlib import Path
import wave
from typing import Dict, List, Tuple, Union


@dataclass
class Word:
    transcript: str
    interval: List[float]

    @property
    def start(self) -> float:
        return self.interval[0]

    @property
    def end(self) -> float:
        return self.interval[1]

    @property
    def data(self) -> Dict[str, Union[str, List[float]]]:
        return {"interval": self.interval, "word": self.transcript}


@dataclass
class Segment:
    words: List[Word]
    start: float
    end: float
    index: int
    parent_uuid: str

    @property
    def id(self) -> str:
        return f"{self.parent_uuid}_{self.index:05d}_{self.start}-{self.end}"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("-i", "--input-filepath", type=str, help="Mod9 output json")
    parser.add_argument("-a", "--audio-filepath", type=str, help="Path of audio file to be segmented")
    parser.add_argument("-o", "--output-filepath", type=str, help="Text file to save split times")
    parser.add_argument("-d", "--segments-dir", type=str, help="Directory to save the segments to")
    parser.add_argument("-t", "--segment-time", type=int, default=7, help="Target length for each segment")
    return parser.parse_args()


def get_audio_duration_in_seconds(path: str) -> float:
    with wave.open(path, "rb") as wavefile:
        rate = wavefile.getframerate()
        return wavefile.getnframes() / float(rate)


def get_word_intervals_and_audio_length(mod9_output_filepath: str, audio_filepath: str) -> Tuple[List[Word], float]:
    """Find word intervals in audio and audio length based on mod9 output"""
    words: List[Word] = []
    with open(mod9_output_filepath) as inp:
        mod9_data = json.load(inp)
    for segment in mod9_data["result"]:
        if 'words' in segment:
            words += [Word(word["word"], word["interval"]) for word in segment["words"]]
        else:
            words.append(Word("$SILENCE", segment["interval"]))
    audio_length = get_audio_duration_in_seconds(audio_filepath)
    return words, audio_length


def get_word_boundary_times(words: List[Word]) -> List[float]:
    """Find potential times to split audio based on word boundaries"""
    boundary_times = []
    for left_word, right_word in zip(words[:-1], words[1:]):
        left_boundary = left_word.end
        right_boundary = right_word.start
        boundary_time = (left_boundary + right_boundary) / 2
        boundary_times.append(round(boundary_time, 2))
    return boundary_times


def get_split_times(boundary_times: List[float], target_duration: int, audio_length: float) -> List[float]:
    """Find the best times to split based on the clip target duration"""
    split_times = []
    last_split_time = 0.0
    while boundary_times and target_duration < audio_length - last_split_time:
        target_time = last_split_time + target_duration
        closest_time = min(boundary_times, key=lambda x: abs(x - target_time))
        if audio_length - closest_time < 2:
            # do not split, if last chunk would be less than 2 seconds
            break
        split_times.append(closest_time)
        last_split_time = closest_time
        # Only consider split candidates that are bigger than the current split time
        boundary_times = [bt for bt in boundary_times if closest_time < bt]
    return split_times


def segment_words_on_split_times(
    words: List[Word], split_times: List[float], audio_length: float, uuid: str
) -> List[Segment]:
    """Split the sequence of words based on the given split times"""
    segments = []
    start = 0.0
    i = 0
    for split_time in split_times:
        segment_words = [word for word in words if start <= word.start and word.end <= split_time]
        segments.append(Segment(segment_words, start, split_time, i, uuid))
        start = split_time
        i += 1
    words = [word for word in words if start <= word.start]
    segments.append(Segment(words, start, audio_length, i, uuid))
    return segments


def write_segment_to_json_file(words: List[Word], output_filepath: str) -> None:
    data = {"result": [word.data for word in words]}
    with open(output_filepath, "w", encoding="utf-8") as outp:
        json.dump(data, outp)


def write_segment_to_html_file(words: List[Word], output_filepath: str) -> None:
    with open(output_filepath, "w", encoding="utf-8") as outp:
        outp.writelines(
            '<div class="asrTranscript" style="border: 1px solid #F2F3F4; background-color: #F8F9F9; border-radius: 5px; padding: 7px; margin: 10px 0;">\n'
        )
        outp.writelines('    <p class="asrTranscriptContent" >\n')
        for word in words:
            outp.writelines(f"<span title='interval{json.dumps(word.interval)}'>{word.transcript}</span> ")
        outp.writelines("    </p>\n")
        outp.writelines("</div>\n")


def write_segments_info_to_file(segments: List[Segment], filepath: str) -> None:
    with open(filepath, "w") as outp:
        for segment in segments:
            line = f"{segment.start};{segment.end};{segment.id}\n"
            outp.write(line)


def create_output_files(segments, output_filepath: str, segments_dir: str) -> None:
    write_segments_info_to_file(segments, output_filepath)
    for segment in segments:
        path_stem = os.path.join(segments_dir, segment.id)  # path/to/segment_id
        write_segment_to_json_file(segment.words, path_stem + ".json")
        write_segment_to_html_file(segment.words, path_stem + ".html")


def main():
    args = parse_args()
    uuid = Path(args.input_filepath).stem
    words, audio_length = get_word_intervals_and_audio_length(args.input_filepath, args.audio_filepath)
    boundary_times = get_word_boundary_times(words)
    split_times = get_split_times(boundary_times, args.segment_time, audio_length)
    segments = segment_words_on_split_times(words, split_times, audio_length, uuid)
    create_output_files(segments, args.output_filepath, args.segments_dir)


if __name__ == "__main__":
    main()
