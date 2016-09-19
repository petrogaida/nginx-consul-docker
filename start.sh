docker rm $(docker ps -q -a) -f

echo "Enter HOST_IP or press enter for default(172.17.0.1) - this is your docker machine or engine IP address using for bridge connection"
read host

if [[ $host = "" ]]; then		
	host="172.17.0.1"
fi

export HOST_IP=$host

docker-compose up -d
docker exec -ti consul apk update
docker exec -ti consul apk add jq
