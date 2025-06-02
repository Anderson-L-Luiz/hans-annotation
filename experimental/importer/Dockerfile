FROM node:lts-alpine

# make the 'app' folder the current working directory
WORKDIR /app

# copy both 'package.json' and 'package-lock.json' (if available)
COPY ./vue/package*.json ./

# install project dependencies
RUN apk add --no-cache \
    && npm install -g npm@8.10.0

RUN apk add --no-cache \
    && npm install -g http-server \
    && npm install vue@latest @vue/cli@latest \
    && npm install @vue/cli-service@latest \
    && npm install

# copy project files and folders to the current working directory (i.e. 'app' folder)
COPY ./vue .

# build app for production with minification
RUN npm run build

EXPOSE 8084
CMD [ "http-server", "-p 8084", "dist" ]
# , "--cors"
