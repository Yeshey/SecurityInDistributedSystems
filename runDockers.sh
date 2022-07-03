#!/bin/bash

#echo "Docker restart, in case iptables is messed up?"
#service docker restart

echo "Deleting all docker images..."
docker rm -vf $(docker ps -aq)
docker rmi -f $(docker images -aq)

echo "Creating user defined bridge networks for dockers to communicate..."
# https://www.tutorialworks.com/container-networking/
docker network create rusty-net

echo "Building Apache docker..."
(docker build -t svs:latest ./DockerApache/
docker run -d -p 80:80 -p 443:443 --net rusty-net --name svs svs:latest
echo "Finished Building & Running Apache docker") &

echo "Building Node Backend docker..."
(docker build -t backend/node-web-app ./DockerNodeJS/
docker run -p 8080:3000 -d --net rusty-net --name backend backend/node-web-app
echo "Finished Building & Running Node Backend docker") &

# https://stackoverflow.com/questions/6156541/threads-in-bash
wait
echo "Finished Building & Running Everything"