# nginx-consul-docker
This demo briefly shows main capabilities of nginx plus, consul and docker in Microservices architecture.

![alt tag](http://s10.postimg.org/qctsvzjkp/nginx_diagram.png)

Used components:
* [NGINX Plus](http://nginx.com/) - load balancer and API Gateway.
* [Consul](https://www.consul.io/) - dynamic discovery of microservices location.
* [Docker](https://www.docker.com/) - software containerization platform  for implemented microservices.
* [Registrator](https://github.com/gliderlabs/registrator) - monitors Docker activity and push details about started or stopped microservices instances to the Consul.

#### *Installation:*
##### Prerequisites and Required Software:

- [docker](https://www.docker.com/products/docker)
- [docker-compose](https://docs.docker.com/compose/install/)
- [jq](https://stedolan.github.io/jq/)

**Steps to run:**

1. `$ git clone https://github.com/petrogaida/nginx-consul-docker`.
2. Copy *nginx-repo.key* and *nginx-repo.crt* files for your account to *~/nginx* folder (those files are already there, but they need to be replaced with new one, because current could be expired).
3. run `$ ./start.sh` to get all Docker images and start them. Script will ask you to enter *$HOST_IP* - this is your docker host IP (for Ubuntu it is 172.17.0.1), for Windows type `$ docker-machine ip default` to get IP of your host. 

#### *Demo*
Type `$ docker ps`

![alt tag](http://s9.postimg.org/lt55l4ai7/tttt.png)

When your NGINX Plus, Consul and Registrator instances run, you can start running microservices. When you start or stop microservice container, Registrator picks this changes and sends it to Consul, which based on his configuration file will call proper handler (bash file). In this case it will use simple NGINX Plus api to register or deregister microservice instances. Steps to run a demo are below:

1. Go to folder *./microservices*.
2. Type  `$ docker-compose -f http-service.yml scale http=3`, to run 3 instances of simple microservice.
3. Type  `$ docker-compose -f helloworld.yml scale helloworld=2`, to run 2 instances of another microservice.
4. Type  `$ docker-compose -f hellouniverse.yml scale hellouniverse=2`, to run 2 instances of another microservice.

Now you can open your browser and go to:

1. *http://HOST_IP:8080/* - NGINX Plus dashboard page. Here you can monitor your microservices instances.
2. *http://HOST_IP:8500/* - Consul dashboard.
3. *http://HOST_IP:80/endpoint1* - returns "Hello World" by calling *helloworld* microservice.
4. *http://HOST_IP:80/endpoint2* - returns "Hello Universe" by calling *hellouniverse* microservice.
5. *http://HOST_IP:80/loadbalance* - opens page with details about server on which microservice is run currently. You can check "Auto refresh" and monitor NGINX Plus dashboard how it balances between nodes.

#### *How to add a new microservice to NGINX Plus*

1. Go to *./microservices* folder.
2. Create your own *<newmicroservicename>.yml* and enter details about your microservice.

        notes: 
        - image name should use only alpha/numeric and dash symbols for correct work. 
        - add labels "SERVICE_TAGS: production" (Consul registers only services with tag production) 
          and SERVICE_NAME : <your microsevice name> (remember this value, it will be used in Consul watch config).
3. Go to root folder and open file *consul_watches_config.js*. Add new item to watches collection with **_your microsevice name_** and *registerderegister.sh* handler. You can write your own handler for specific services.
4. Go to *./nginx folder*. Open *app.conf* and add a new upstream with **_your microsevice name_** 
    notes: upstream name must be the same as your SERVICE_80_Name, mapping is using those fields.
5. Go to *./nginx/services folder* and create a new file with routes for new added microservices.
6. Restart NGINX Plus and Consul containers.


