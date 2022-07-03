#!/bin/bash

docker rm --force svs
docker build -t svs:latest ./DockerApache/
docker run -d -p 80:80 -p 443:443 --net rusty-net --name svs svs:latest

echo "Finished Building & Running Everything"