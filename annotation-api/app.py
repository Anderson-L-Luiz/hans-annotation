import io
import sys
import json
import os
from datetime import timedelta
from uuid import uuid4
import requests
from requests.auth import HTTPBasicAuth

from pydantic import BaseModel, Field

from flask import Flask, jsonify, redirect, url_for, request
from flask_cors import CORS

from flask_openapi3 import Info, Tag
from flask_openapi3 import OpenAPI, FileStorage

from minio import Minio
from minio.error import MinioException

info = Info(title='Annotation Importer API', version='1.0.0')
app = OpenAPI(__name__, info=info)

# enable CORS
CORS(app, resources={r'/*': {'origins': '*'}})


# Labelstudio auth
labelstudio_auth_token = os.environ['LABEL_STUDIO_USER_TOKEN']
labelstudio_auth_header = {"Authorization" : "Token ___INVALID___", "Content-Type": "application/json", "Accept": "application/json"}
labelstudio_auth_header["Authorization"] = "Token " + labelstudio_auth_token


# Minio auth
minio_auth_user = os.environ['MINIO_ROOT_USER']
minio_auth_password = os.environ['MINIO_ROOT_PASSWORD']


class PublishFilesForm(BaseModel):
    fileVideo: FileStorage
    fileAudio: FileStorage
    fileTranscript: FileStorage
    fileAsrResult: FileStorage
    language: str = Field(None, description="File spoken language identifier")


class UploadFileForm(BaseModel):
    file: FileStorage
    language: str = Field(None, description="File spoken language identifier")


# sanity check route
@app.route("/")
def hello():
    return "Hello world!"


# sanity check route
@app.route('/ping', methods=['GET'])
def ping_pong():
    return jsonify('pong!')

# Helper to create minio connection to annotationdb
def create_minio_client():
    return Minio('annotationdb:9003',
                    access_key=minio_auth_user,
                    secret_key=minio_auth_password,
                    secure=False)


# Helper to check if file exists on minio
def file_exists(bucket, uuid):
    minio_client = create_minio_client()
    found = False
    response = None
    try:
        response = minio_client.get_object(bucket, uuid)
        print("Object " + str(uuid) + " exists on minio!", file=sys.stderr)
        found = True
    except MinioException:
        print("Object " + str(uuid) + " does not exist on minio!", file=sys.stderr)
    finally:
        if response:
            response.close()
            response.release_conn()
    return found


# Helper to publish json data on minio
def publish_json(bucket, uuid, data):
    minio_client = create_minio_client()

    text_data = json.dumps(data).encode("utf-8")
    data_as_a_stream = io.BytesIO(text_data)
    data_as_a_stream.seek(0)
    data_metaMinio = {
        "X-Amz-Meta-Filename": uuid
    }

    try:
        minio_client.put_object(bucket, uuid, data_as_a_stream, len(data_as_a_stream.getvalue()), "application/json", data_metaMinio)
        return True
    except MinioException:
        print("Failed to publish " + str(uuid) + ": " + str(text_data), file=sys.stderr)
        return False

# Helper to publish received files
def publish_single_file(bucket, file, language, mimetype):
    minio_client = create_minio_client()
    uuid = str(uuid4())
    data_as_a_stream = io.BytesIO(file.read())
    metaMinio = {
        "X-Amz-Meta-Filename": file.filename,
        "X-Amz-Meta-Language": language
    }

    try:
        minio_client.put_object(bucket, uuid, data_as_a_stream, len(data_as_a_stream.getvalue()), mimetype, metaMinio)
    except MinioException:
        return {"code": 500, "message": "Failed to publish to storage system!"}
    try:
        url = minio_client.presigned_get_object(bucket, uuid, expires=timedelta(days=30))
        return url
    except MinioException:
        return {"code": 500, "message": "Failed to create pre signed url on storage system!"}


@app.post('/publish')
def publish_files(form: PublishFilesForm):
    videoUrl = publish_single_file("assets", form.fileVideo, form.language, "video/mp4")
    audioUrl = publish_single_file("assets", form.fileAudio, form.language, "audio/wav")
    transcriptUrl = publish_single_file("assets", form.fileTranscript, form.language, "text/plain")
    asrResultUrl = publish_single_file("assets", form.fileAsrResult, form.language, "application/json")

    task = {
        'video': videoUrl,
        'audio': audioUrl,
        'transcript': transcriptUrl,
        'asrResult': asrResultUrl
    }

    minio_client = create_minio_client()

    task_data = json.dumps(task).encode("utf-8")
    task_data_stream = io.BytesIO(task_data)
    task_data_stream.seek(0)

    task_uuid = str(uuid4())
    task_metaMinio = {
        "X-Amz-Meta-Filename": task_uuid,
        "X-Amz-Meta-Language": form.language
    }

    try:
        minio_client.put_object("tasks", task_uuid, task_data_stream, len(task_data_stream.getvalue()), 'application/json', task_metaMinio)
    except MinioException:
        return {"code": 500, "message": "Failed to publish to storage system!"}
    return {"code": 0, "message": task_uuid, "data": task_data}


@app.post('/upload')
def upload_file(form: UploadFileForm):
    minio_client = create_minio_client()
    uuid = str(uuid4())
    value_as_a_stream = io.BytesIO(form.file.read())
    metaMinio = {
        "X-Amz-Meta-Filename": form.file.filename,
        "X-Amz-Meta-Language": form.language
    }

    try:
        minio_client.put_object("raw", uuid, value_as_a_stream, len(value_as_a_stream.getvalue()), 'video/mp4', metaMinio)
    except MinioException:
        return {"code": 500, "message": "Failed to upload to storage system!"}

    try:
        url = minio_client.presigned_get_object('raw', uuid, expires=timedelta(days=2))
    except MinioException:
        return {"code": 500, "message": "Failed to create pre signed url on storage system!"}

    uuidJob = str(uuid4())

    annotationTaskConfig = {
        "token" : {
            "type": "BearerToken",
            "apiAccessToken":"an OAuth2 bearer token",
            "expiresIn":259200
        },
        "input" : [
            {
                "uri": url,
                "filename": form.file.filename,
                "mime-type": "video/mp4",
                "locale": form.language
            }
        ],
        "output" : [
            {
                "url": "http://host.docker.internal:8083/importer/api/publish"
            }
        ]
    }

    response = requests.post('http://host.docker.internal:8080/api/v1/dags/hans_annotation_v1/dagRuns', auth=HTTPBasicAuth('airflow', 'airflow'), json={'dag_run_id': uuidJob, 'conf': annotationTaskConfig})
    if "Bad Request" in response.text:
        return {"code": 500, "message": response.text}
    else:
        return {"code": 0, "message": response.text}


def add_labelstudio_task(project_id, project_name, task_id, task_data, task_name=""):
    """Helper for creating a labelstudio task"""
    print("Adding task " + str(task_id) + " to " + project_name, file=sys.stderr)
    # Extract uuid to store task.json on minio
    video_url = task_data['video']
    start = video_url.find('/assets/') + 8
    end = video_url.find('.mp4', start)
    uuid = video_url[start:end] + ".task" + task_name + ".json"
    print("Task json file: " + str(uuid), file=sys.stderr)
    #print(task_data, file=sys.stderr)
    # Only store and add task if not already existing on minio
    if not file_exists("tasks-audio", uuid):
        response_create_task = requests.post("http://app:8080/api/projects/" + project_id + "/import", headers=labelstudio_auth_header, json=task_data)
        print(response_create_task.status_code, file=sys.stderr)

        publish_json("tasks-audio", uuid, task_data)
        print("Task " + str(task_id) + " added successfuly to " + project_name + "!", file=sys.stderr)
    else:
        print("Task " + str(task_id) + " already exists on " + project_name + "! -> Adding task skipped.", file=sys.stderr)


def get_labelstudio_project_id(project_name):
    """Helper for receive label studio project id from project name"""
    response_projects_list = requests.get("http://app:8080/api/projects", headers=labelstudio_auth_header)
    data = response_projects_list.json()
    task_results = data["results"]
    for item in task_results:
        if item['title'].lower() == project_name.lower():
            return str(item['id'])


@app.post('/webhook/hans_video_snippets')
def webhook_hans_video_snippets():
    """Webhook for HAnS video snippets, automatically adds hans_audio_annotation tasks if ASR Error is labeled"""
    content = request.get_json(silent=True)
    task_action = content['action']
    task_id = content['task']['id']

    print(str(task_action), file=sys.stderr)
    print("Task id: " + str(task_id), file=sys.stderr)
    #print(json.dumps(content, indent=2), file=sys.stderr)

    task_results = content['annotation']['result']
    asr_error_found = False
    anonymization_required_found = False
    speaker_unintelligible_found = False
    for item in task_results:
        if item['from_name'] == "asrError":
            if item['value']['choices'][0] == "True":
                asr_error_found = True
        if item['from_name'] == "asrCorrect":
            if item['value']['choices'][0] == "False":
                asr_error_found = True
        if item['from_name'] == "anonymizationRequired":
            if item['value']['choices'][0] == "True":
                anonymization_required_found = True
        if item['from_name'] == "speakerIntelligible":
            if item['value']['choices'][0] == "False":
                speaker_unintelligible_found = True

    if asr_error_found and not speaker_unintelligible_found:
        asr_result_url = content['task']['data']['asrResult']
        minio_client = create_minio_client()
        asr_url_splitted = asr_result_url.split('/')
        try:
            response = minio_client.get_object(asr_url_splitted[-2], asr_url_splitted[-1])
            asr_data = json.loads(response.read())
            transcript_text = ""
            for item in asr_data['result']:
                transcript_text = transcript_text + item['word'] + " "
            content['task']['data']['transcriptText'] = transcript_text.strip()
        finally:
            response.close()
            response.release_conn()

        project_id = get_labelstudio_project_id("HAnS Audio Transcription")
        add_labelstudio_task(project_id, "HAnS Audio Transcription", task_id, content['task']['data'])
    else:
        print("No transcription action required for Task id: " + str(task_id), file=sys.stderr)

    if anonymization_required_found:
        project_id = get_labelstudio_project_id("HAnS Audio Speaker Diarization")
        add_labelstudio_task(project_id, "HAnS Audio Speaker Diarization", task_id, content['task']['data'], ".anonymization")
    else:
        print("No anonymization action required for Task id: " + str(task_id), file=sys.stderr)

    return {"code": 0, "message": "ok"}


# Get Available DAG's
@app.get('/dags')
def get_dags():
    # TODO Static auth for airflow!
    responseDags = requests.get('http://host.docker.internal:8080/api/v1/dags', auth=HTTPBasicAuth('airflow', 'airflow'))
    return {"code": 0, "message": responseDags.text}


if __name__ == '__main__':
    app.run(port=5002, debug=True, host='0.0.0.0')
