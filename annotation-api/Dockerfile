FROM python:3.9-alpine

ENV FLASK_APP=app.py
ENV FLASK_RUN_HOST=0.0.0.0

WORKDIR /code
COPY requirements.txt .
EXPOSE 5002
RUN pip3 install --upgrade pip && pip3 install --upgrade setuptools && pip3 install markupsafe && pip3 install -r requirements.txt
COPY . .
CMD [ "flask", "run", "--host=0.0.0.0", "--port=5002"]
