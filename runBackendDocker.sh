#!/bin/bash

docker rm --force backend
docker build -t backend/node-web-app ./DockerNodeJS/
docker run -p 8080:3000 -d --net rusty-net --name backend backend/node-web-app

echo "Finished Building & Running Everything"