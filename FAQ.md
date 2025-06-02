# Annotation FAQ

This document contains hints for annotating the video snippets in label studio.

## Project HAnS Video Snippets

### Annotation Questions

#### Slide visible?

Tick yes, if there is a slide visible in the video snippet.

#### Slide changed?

Mark only one video snippet where the switch to the new slide finishes.
Don't mark multiple snippets for the same slide change.

- Animations, e.g. zoom animations on the same slide should not be considered as a slide change!

#### Example presented?

Annotation entry is required to determine examples which could be used for
training of AI-Tutor. The lecturer is presenting the students, e.g. "Formula calculations".

Interval:

- The start of the example will result in a "yes" on the first video snippet.
- The question will be labeled as "yes" as long as the teacher is presenting the same example for the following video snippets.
- The last snippet were the teacher finishes the example is still labeled as "yes".
- The next snippet where the example is not shown anymore will be labeld as "no".

#### Exercise presented?

Annotation entry is required to determine exercises which could be used for
training of AI-Tutor. The lecturer is presenting the students, e.g. "Exercise on basic computer math".

Interval:

- The start of the exercise will result in a "yes" on the first video snippet.
- The question will be labeled as "yes" as long as the teacher is presenting the same exercise for the following video snippets.
- The last snippet where the teacher finishes the exercise is still labeled as "yes".
- The next snippet where the exercise is not shown anymore will be labeled as "no".

#### (White-)Board or other teaching aids used?

Tick yes, if the teacher uses a board, e.g. whiteboard, or other teaching aids besides the slides in the video.
The question will be answered with "yes" as long as the teacher uses teaching aids, example flow:

Interval:

- The first change to the teaching aids will result in a "yes" on the first video snippet.
- The question will be labeled as "yes" as long as the teacher is using the teaching aids for the following video snippets.
- The last snippet where the teacher comes back to the slides is still labeled as "yes".
- The next snippet where no teaching aid is used anymore will be labeled as "no".

#### Chapter/Topic started?

Tick yes, if the lecturer is starting or switching to a new chapter, subchapter, or topic in the video.
Teaching content that is talked about for a longer period of time.
It is not needed to follow slide headings, you should refer to meaning sections.

- Event: Should be only set to "yes" on one snippet the next snippet should set the question to "no" again

#### Voice of s.o. else heard? (e.g. student)

Tick yes, if there is anyone besides the lecturer speaking in the video, e.g. a student.
The focus of this question are mainly the spoken words, so sneezing, coughing etc. is not relevant.

#### Transcription contains speech of s.o. else?

Tick yes, if the transcription contains text which was not spoken by the lecturer
(-> are there words in the transcript which were spoken by another person, e.g. a question of a student?).

#### Error in transcription? \[DEPRECATED\]

Tick yes, if the transcription does not match the spoken words in the video snippet.
For an overview of what is considered an error, see the section "Transcript" below.

#### Transcription correct?

Tick yes, if the transcription matches the spoken words in the video snippet.
For an overview of what is considered an error, see the section "Transcript" below.

#### Meaning preserved in Transcription?

Determine if the meaning of what is said is preserved despite errors in the transcription.
The text is correct in content and the logic is preserved.

#### Specialist term spoken?

Check if there is a specialist term spoken in the audio of the snippet.
The distinction of "what a specialist term is" does not have to be super precise here.
If you are unsure if there is a specialist term, better click "yes".

#### Formula spoken? (Only video snippet template `science`)

Check if there is a formula spoken in the audio, e.g. "y equals a times x".

#### Variable/letter spoken? (Only video snippet template `science`)

Check if there is a variable or letter spoken in the audio, e.g. "if we change n here there might be..."

#### Speaker acoustically intelligible?

Tick this, if a speaker in the video is acoustically not understandable,
e.g. if there are audio issues in some parts of the snippet, which cause that some speech in the video cannot be understood.

## Transcript

### Punctuation is not relevant

Punctuation, e.g. full stops or quotes, are not included in the transcript and thus are not relevant for checking the transcription.

### Missing Words

Missing words are considered as error, e.g. if the speaker is saying "im" and it is not included in the transcript, this is an error! This also includes missing filler words, e.g. "ähm".

### Filler Words

Filler words, e.g. "ähm" should be detected and included in the transcript.

### Interrupted Words

Interrupted words are included as they are spoken. If they are mapped to other words, this is an error!
E.g. "vol volumen", the speaker stopped after speaking "vol" and then spoke the complete word "volumen".

### Year Numbers

Year numbers are written completely in the transcript, e.g. "four hundred fifty one" or "vier hundert ein und fünfzig".
Take care and ensure that the writing of these is correct.

### Formulas

Formulas are written completely in the transcript, e.g. "square root of a minus b".
Take care and ensure that the writing of these is correct.

### Abbreviations

Abbreviations should be part of the transcript.
If the transcript contains the fully written form of the term, e.g. "unter dem" instead of "unterm", this is an error.

### Compound Word Errors Over Multiple Snippets

If a compound word is at the end of the snippet and not recognized fully within the snippet, example:

- "vervielfältig" is at the end of the snippet with id 1
- "bar" is at the beginning of the next snippet with id 2
- The compound word "vervielfältigbar" was not recognized correctly

Please report the corresponding two snippet ids and the compound word to the development team.

### Out Of Vocabulary Words

If you suspect that words have not been recognized because they seem to be not in the used lexicon,
please report them back to the development team.
Out Of Vocabulary (OOV) words are for example:
"Kanalisationssystem", recognized as "Kanalisation Systeme" is an error

### Checking Word Intervals

It is possible to see the exact timestamps for each word by hovering on the specific word in the transcript, e.g. in the "HAnS Video Snippets" project:

![Hover](./docs/images/hover_transcript.png "Hover")

You can lookup the timestamp in the full transcript using the "HAnS Video Annotation" project (main menu in blue color). "HAnS Video Annotation" contains the full length video and it's transcript.
You can try to search in the browser for the timestamp or the words:

![Lookup](./docs/images/lookup_full_transcript.png "Lookup")
