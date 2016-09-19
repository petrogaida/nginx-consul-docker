docker rm $(docker ps -q -a) -f
docker rmi $(docker images -q) -f
./start.sh
