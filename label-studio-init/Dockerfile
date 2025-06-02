FROM debian:bullseye-slim
RUN apt-get -y update && apt-get -y upgrade \
 && apt-get install -y wget curl netcat python3 python3-pip \
 && apt-get -y clean \
 && apt-get -y autoremove \
 && rm -rf /var/lib/apt/lists/*
RUN pip3 install requests Jinja2
WORKDIR /code
COPY . .
ENV LANG C.UTF-8
RUN cd /code && chmod +x init.sh && chmod +x get_project_id_for_project_title.py \
&& chmod +x get_project_info.py && chmod +x create_project_config.py && chmod +x create_webhook_config.py
