# Initialization

The initialization of [labelstud.io](https://labelstud.io) is done using HTTP requests to the [labelstud.io API](https://labelstud.io/api#operation/api_projects_create) to create the corresponding projects.

The projects for HAnS are generated using the JSON configurations and templates in the [`projects` subfolder](./projects/).
The [`dev_templates`](./dev_templates/) folder is used for developing experimental project templates in the default label-stud.io format.
After the experimental template is finished it will be integrated to the template generation mechanism in the [`projects` subfolder](./projects/).

## Update Tasks

`update_tasks.py` allows to update the task meta data of existing tasks.

Parameters:

- `-b` specifies the beginning of the task id range. Note: If you want to update only one task begin and end should be the same task id
- `-e` specifies the end of the task id range
- `-m` specifies the path to the metadata file to be used for updating
- `-s` the hostname were labelstud.io app is running
- `-p` the port were labelstud.io app is running
- `-t` the token needed to connect to labelstud.io app
- `-v` specifies one of the following task types:
  - `standard`: A task with a complete video
  - `snippet`: A task which contains a part of a video (splitted). Interval and split index will be added.

Example call for updating one `standard` task:

```bash
python3 update_tasks.py -b 1 -e 1 -m "label.meta.json" -s "localhost" -p 8083 -t "0815d3mdm" -v "standard"
```

Example call for updating multiple `snippet` tasks:

```bash
python3 update_tasks.py -b 7235 -e 7404 -m "label.meta.json" -s "localhost" -p 8083 -t "0815d3mdm" -v "snippet"
```
