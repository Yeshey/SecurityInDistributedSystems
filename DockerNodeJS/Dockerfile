#FROM node:16
# https://nodejs.org/en/docs/guides/nodejs-docker-webapp/


# https://linuxhint.com/build_nodejs_app_docker/
FROM node:carbon
WORKDIR /usr/src/app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["node", "index.js"]

# run 
# docker build -t backend/node-web-app . ; docker run -p 8080:3000 -d --name backend backend/node-web-app

# test with
# curl localhost:8080