FROM debian:bullseye-slim
RUN apt-get -y update && apt-get -y upgrade \
 && apt-get install -y wget curl netcat python3 python3-pip bc ca-certificates \
 && apt-get -y clean \
 && apt-get -y autoremove \
 && rm -rf /var/lib/apt/lists/*
RUN pip3 install requests Jinja2
WORKDIR /code
COPY . .
ENV LANG C.UTF-8
RUN cd /code && chmod +x publish.sh && chmod +x publish_annotation_task.sh \
&& chmod +x publish_multimedia_tasks.sh && chmod +x publish_multimedia_tasks_for_projects.sh \
&& wget https://dl.min.io/client/mc/release/linux-amd64/mc && chmod +x mc \
&& chmod +x get_project_id_for_project_title.py && update-ca-certificates
