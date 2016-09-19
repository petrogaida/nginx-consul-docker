#!/bin/bash
CURL='/usr/bin/curl'
OPTIONS='-s'
CONSUL_SERVICES_API="http://$HOST_IP:8500/v1/catalog/services"
CONSUL_SERVICE_API="http://$HOST_IP:8500/v1/catalog/service"
STATUS_UPSTREAMS_API="http://$HOST_IP:8080/status/upstreams"
UPSTREAM_CONF_API="http://$HOST_IP/upstream_conf?"

# Get the list of current Nginx upstreams
upstreams=$($CURL $OPTIONS $STATUS_UPSTREAMS_API | jq -r '. as $in| keys[]')
consul_services=$($CURL $OPTIONS $CONSUL_SERVICES_API | jq --raw-output 'to_entries| .[] | select(.value[0] == "production") | .key')

all_consul_entries=()
for service in ${consul_services[@]}; do
	if [[ ! $upstreams =~ $service ]]; then
		continue
	fi
	ports=$($CURL $OPTIONS $CONSUL_SERVICE_API/$service | jq -r '.[]|.ServicePort')
	for port in ${ports[@]}; do
		all_consul_entries+=("$service;$HOST_IP:$port")
	done
done

all_nginx_entries=()
for upstream in ${upstreams[@]}; do
	upstream_existing_services=$($CURL $OPTIONS {$UPSTREAM_CONF_API}upstream=$upstream)
	ip=''
	for part in ${upstream_existing_services[@]}; do
		if [[ $part =~ ":" ]]; then
			ip=$part
			continue
	    elif [[ $part =~ "id=" ]]; then
			all_nginx_entries+=("$upstream;${ip::-1};$part")
	    else
			continue
	    fi
	done
done

for entry in ${all_consul_entries[@]}; do
	IFS=';' read -a splittedValues <<< "$entry"
	upstream_name=${splittedValues[0]}
	service_ip=${splittedValues[1]}
	
	if [[ ! ${all_nginx_entries[@]} =~ $service_ip ]]; then		
		$CURL $OPTIONS "{$UPSTREAM_CONF_API}add=&upstream=$upstream_name&server=$service_ip"
		echo "Added $service_ip to the nginx upstream group $upstream_name!"
	fi
done

for entry in ${all_nginx_entries[@]}; do
	IFS=';' read -a splittedValues <<< "$entry"
	upstream_name=${splittedValues[0]}
	upstream_service_ip=${splittedValues[1]}
	upstream_service_id=${splittedValues[2]}
	if [[ ! ${all_consul_entries[@]} =~ $upstream_service_ip ]]; then
		$CURL $OPTIONS "{$UPSTREAM_CONF_API}remove=&upstream=$upstream_name&$upstream_service_id"
		echo "Removed $upstream_service_ip # $upstream_service_id from nginx upstream block $upstream_name!"
	fi
done
