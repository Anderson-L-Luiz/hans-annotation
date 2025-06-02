FROM debian:bullseye-slim

RUN apt-get -y update && apt-get -y upgrade && apt-get -y install -y netcat \
    vim \
    nano \
    wget \
    curl \
 && apt-get -y clean \
 && apt-get -y autoremove \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /code

COPY . .

ENV LANG C.UTF-8
RUN cd /code && chmod +x init.sh && wget https://dl.min.io/client/mc/release/linux-amd64/mc && chmod +x mc
