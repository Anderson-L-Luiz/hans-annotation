# HAnS External Annotation Tool

It is possible to use an external annotation tool instead of the integrated annotation mechanisms of [HAnS](https://github.com/th-nuernberg/hans) to label training data.

## Overview

For labeling with an external annotation tool we use [labelstud.io](https://labelstud.io) as the basis.
The labeling templates for [HAnS](https://github.com/th-nuernberg/hans) are located in [`label-studio-init/projects/templates`](./label-studio-init/projects/templates).
The corresponding default projects are located in [`label-studio-init/projects`](./label-studio-init/projects) and initialized using [label-studio-init](./label-studio-init).

## Getting Started

### Prerequisites

- 64-bit operating system
  - Linux distribution, e.g. Debian, Ubuntu or other
    - Recommended [Ubuntu Server 20.04 LTS](https://ubuntu.com/download/server)

- [Docker](https://www.docker.com/)
  - Check [supported Docker server platforms](https://docs.docker.com/engine/install/#server)
  - Recommended is to [install Docker on Ubuntu](https://docs.docker.com/engine/install/ubuntu/), see [Docker OS requirements](https://docs.docker.com/engine/install/ubuntu/#os-requirements)

- [docker compose](https://docs.docker.com/compose/)
  - See instructions to [Install Docker Compose](https://docs.docker.com/compose/install/)

- [Git](https://git-scm.com/)
  - See [installing Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) for instructions how to install Git on your server

- [Git Large File Storage (LFS)](https://git-lfs.github.com/)
  - See [Getting Started](https://git-lfs.github.com/), you only need to run this once per user account on your server:

  ```bash
  git lfs install
  ```

- [ffmpeg](https://ffmpeg.org/)
  - Use the OS specific package installers to install ffmpeg, e.g.:

  ```bash
  sudo apt-get install ffmpeg
  ```

- [Python 3](https://www.python.org/)
  - For creating annotation tasks, you need to have python3 (>=3.5) installed on your system
  - See the [official python download page](https://www.python.org/downloads/)

### Installation

- Open a linux shell

- Clone the git repository

```bash
git clone https://github.com/th-nuernberg/hans-annotation.git
```

### Starting the Docker Containers

- Use `start.cmd` to start the docker containers on one machine:

```bash
cd hans-annotation
./start.cmd
```

- `start.cmd` can be run with optional flags:
  - `-b`: Rebuilds the images.
  - `-e`: Enable the signup option in the labeling tool. If not set, only people who receive an invitation link can sign up.

### Login

Open a browser on [localhost:8083](http://localhost:8083).

Use the default credentials for login:

- User: `hans@localhost`
- Password: `hans`

#### Default Projects

After the login you see the following default projects.
Initial projects were developed in [development templates](./label-studio-init/dev_templates/).
We use a generator to dynamically create the projects, see [projects documentation](./label-studio-init/projects/README.md)
and [initialization documentation](./label-studio-init/README.md)

- `HAnS Audio Transcription`: Contains the small video snippets audio and ASR result for correcting the transcription
- `HAnS Audio Speaker Diarization`: Contains the small video snippets audio for speaker diarization annotation
- `HAnS Video Annotation`: Contains the full length videos for annotation
- `HAnS Video Snippets`: Contains the small video snippets for annotation, uses webhooks to create tasks for `HAnS Audio Transcription` and `HAnS Audio Speaker Diarization`
- `HAnS Video Snippets - Science`: Contains the small video snippets for annotation and additional science related questions, uses webhooks to create tasks for `HAnS Audio Transcription` and `HAnS Audio Speaker Diarization`

##### WarmUp Projects

Warmup projects could be used by new annotators to train labeling:

- `HAnS Video Snippets WarmUp 01`: Contains the small video snippets for annotation
- `HAnS Video Snippets WarmUp 02`: Contains the small video snippets for annotation
- `HAnS Video Snippets WarmUp 03`: Contains the small video snippets for annotation
- `HAnS Video Snippets WarmUp 04`: Contains the small video snippets for annotation

#### Annotation Instructions

`HAnS Video Snippets` is the main project which should be used for annotation.
For additional hints and instructions for annotation see [FAQ](FAQ.md).

### Create Annotation Task

Each annotation template requires an annotation task JSON configuration file (e.g. [example-files/sintel/label.meta.json](./example-files/sintel/label.meta.json)) to be imported for each file.

Example files are stored in [example-files/sintel](./example-files/sintel).

Use `create_annotation_task.cmd` to create and import the annotation task to the default projects.
It will create a task for the `HAnS Video Annotation` and multiple tasks for `HAnS Video Snippets` project.
The name of the lecturer and the title of the lecture can also be included for e.g. filtering in label studio.

Example using [example-files/sintel](./example-files/sintel):

```bash
cd hans-annotation
./create_annotation_task.cmd -f example-files/sintel/videos/Sintel.test.mp4 \
-e mod9 \
-l en \
-s localhost \
-t "Sintel Trailer" \
-m example-files/sintel/label.meta.json \
-p science
```

Note: `-e` parameter is setting for the ASR engine, currently only supporting `mod9` or `whisper`, default: `mod9`

In order to encode snippets on a dedicated system instead of the same system
label studio is running on, the `create_annotation_snippets.cmd` and
`publish_annotation_task.cmd` scripts can be used instead.

To encode and split a video into snippets for annotation:

```bash
./create_annotation_snippets.cmd -f example-files/sintel/videos/Sintel.test.mp4 -e mod9 -l en
```

Note: `-e` parameter is setting for the ASR engine, currently only supporting `mod9` or `whisper`, default: `mod9`

This will store the encoded video and snippets in a folder using the filename
without its extension and a generated UUID in its name such as
"Sintel.test_5a171cb8-665e-4840-a2db-97527731394d". Note that the UUID will
differ between runs. This folder can then be moved to the server on which the
label studio instance is running and published:

```bash
./publish_annotation_task.cmd -i Sintel.test_5a171cb8-665e-4840-a2db-97527731394d -f original_file.mp4 -s localhost -t "Sintel Trailer" -m example-files/sintel/label.meta.json -p science'
```

#### Create Annotation Tasks from Upload Bundles

Example upload bundle is stored in [example-files/sintel](./example-files/sintel).

Use `run_create_annotation_task.cmd` to create and import annotation tasks to the default projects.
It will create one task per video for the `HAnS Video Annotation` and multiple tasks for `HAnS Video Snippets` project.
Meta data for the tasks is inserted from JSON configuration file (e.g. [example-files/sintel/label.meta.json](./example-files/sintel/label.meta.json)).
Each upload bundle should contain a `label.meta.json` for labelstud.io and a main meta data file `meta.json` which is used by HAnS ml-backend.

Note: `-p` parameter is currently only supporting `science` or `standard` as warm up projects should not be initialized with complete upload bundles

Example using [example-files/sintel](./example-files/sintel):

```bash
cd hans-annotation
./run_create_annotation_task.cmd -i example-files/sintel \
-e mod9 \
-l en \
-s localhost \
-p science
```

Note: `-e` parameter is setting for the ASR engine, currently only supporting `mod9` or `whisper`, default: `mod9`

#### Languages

The parameter `-l` sets the video language to be used for the automatic speech recognition engine.

Available languages:

- `en`
- `de`

Default: `de`

#### Annotation Database Server

The parameter `-s` sets the hostname of the server to create the correct video and asset urls for the annotation tasks.
This is needed if hosted in a real server environment.

Default: `localhost`

#### Time Interval for Segmentation

The parameter `-x` sets the time interval of the video snippets in seconds.
It is used to split the video into video snippets for the `HAnS Video Snippets` project.

Default: `7`

#### Metadata File

The parameter `-m` sets the path to the metadata file,
containing additional information to the video.
Have a look at the [example file](example-files/sintel/label.meta.json) to see the target format.

#### Video Snippet Template

The parameter `-p` sets the template used for the video snippet annotation task.
This affects the questions asked per snippet (for questions see the [FAQ doc](./FAQ.md)).
Currently available templates:

- `standard`: default questions (subject-independent)
- `science`: adds 2 more science-specific questions to `standard` (use e.g. for physics lectures)
- `warmup`: use warmup project for onboarding labelers,
   works only in combination with [warmup ID parameter(`-w`)](#warmup-id)

##### Warmup Id

The parameter `-w` defines the warmup ID, to which the tasks should be added.
Only relevant if [template parameter (`-p`)](#video-snippet-template) is set to `warmup`.

## Experimental

### Importer (Not working currently)

The experimental importer webpage is available on [localhost:8083/importer](http://localhost:8083/importer).
It will use the url `mlBackendUrl` in `config.json` to create the annotation tasks using an available [ml-backend hans_annotation_v1 Airflow DAG of HAnS](https://github.com/th-nuernberg/hans/tree/main/ml-backend/dags), this feature is not available yet!

## Troubleshooting

### Docker Environment

Depending on the docker environment setup, the docker engine might run with root privileges.
If the docker engine runs with root privileges please disable `user: "$UID:$GID"` in `docker-compose.yaml` for the service `db`.
