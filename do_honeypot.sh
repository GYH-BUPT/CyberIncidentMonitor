#!/bin/bash

CONTAINER_NAME="$2"
INSTRUCTION="$1"

main() {
        case $INSTRUCTION in
                build)
                        build ;;
                create)
                        create ;;
                exec)
                        exec ;;
                start)
                        start ;;
                stop)
                        stop ;;
                remove)
                        remove ;;
                create_dmz_net)
                        create_dmz_net ;;
                help)
                        help ;;
                *)
                        echo $"Usage: $0 {build|create|exec|start|stop|remove|create_dmz_n$
                        exit 1
esac

}

# Build the cowrie image
build() {
        docker build -t cowrie -f ./DockerFile .
        echo "Built cowrie image successfully."
        # define dmz net
        create_dmz_net
}

			
# Create the docker container, giving it name "CONTAINER_NAME"
create() {
        check_container_exists
        # Create the required host directories if they don't already exist
        mkdir -p cowrievolumes/$CONTAINER_NAME/dl       # Malware checksums
        mkdir -p cowrievolumes/$CONTAINER_NAME/log/tty  # Cowrie logs
        mkdir -p cowrievolumes/$CONTAINER_NAME/data     # fs.pickle and userdb.txt

        # Copy config files/log files into the volume being mounted
        cp "$(pwd)"/userdb.txt "$(pwd)"/cowrievolumes/$CONTAINER_NAME/data/userdb.txt
        cp "$(pwd)"/cowrie.cfg.dist "$(pwd)"/cowrievolumes/$CONTAINER_NAME/cowrie.cfg
        cp "$(pwd)"/fs.pickle "$(pwd)"/cowrievolumes/$CONTAINER_NAME/data/fs.pickle
        cp "$(pwd)"/cowrie.log "$(pwd)"/cowrievolumes/$CONTAINER_NAME/log/cowrie.log
        cp "$(pwd)"/cowrie.json cowrievolumes/$CONTAINER_NAME/log/cowrie.json
        echo "Setting logging name to $CONTAINER_NAME in cowrie.cfg"
        sed -i 's/^\(sensor_name\s*=\s*\).*/\1'"$CONTAINER_NAME"'/' "$(pwd)"/cowrievolumes$

        # create the container on network dmz mounting the volumes
        docker create --network="dmz" --name $CONTAINER_NAME \
                -v "$(pwd)"/cowrievolumes/$CONTAINER_NAME/dl:/cowrie/cowrie-git/dl \
                -v "$(pwd)"/cowrievolumes/$CONTAINER_NAME/log:/cowrie/cowrie-git/log \
                -v "$(pwd)"/cowrievolumes/$CONTAINER_NAME/data:/cowrie/cowrie-git/data \
                cowrie:latest
        docker cp "$(pwd)"/cowrievolumes/$CONTAINER_NAME/cowrie.cfg $CONTAINER_NAME:/cowri$
}


exec () {
        echo "Enter CTRL-P + CTRL-Q to exit container without terminating"
        docker exec -it $CONTAINER_NAME /bin/bash
}

# Start the docker container
start() {
	docker start $CONTAINER_NAME
}

# Stop the docker container
stop() {
	docker stop $CONTAINER_NAME
}

# Remove the docker container
remove() {
        echo "Removing container $CONTAINER_NAME" && \
                docker rm -f $CONTAINER_NAME &> /dev/null || true
        echo "Preserving container directories - delete manually if required"

}

# Local DMZ bridge network to which all containers are connected
create_dmz_net() {
        network_exists=$( sudo docker network ls | grep "dmz" ) 
        if [[ -n "$network_exists" ]] ; then
                echo "DMZ network defined"
        else
                echo "Creating DMZ network (10.0.0.0/8)"
                docker network create -d bridge --subnet 10.0.0.0/8 dmz
        fi

        # define a router
        define_router
}

define_router() {
        CONTAINER_NAME="router"
        router_defined=$(sudo docker ps -a | grep "router" )
        if [[ -n "$router_defined" ]] ; then
                echo "Router defined"
        else
                mkdir -p cowrievolumes/$CONTAINER_NAME/dl       
                mkdir -p cowrievolumes/$CONTAINER_NAME/log/tty
                mkdir -p cowrievolumes/$CONTAINER_NAME/data     
                cp "$(pwd)"/userdb.txt "$(pwd)"/cowrievolumes/$CONTAINER_NAME/data/userdb.$
                cp "$(pwd)"/fs.pickle "$(pwd)"/cowrievolumes/$CONTAINER_NAME/data/fs.pickle
                cp "$(pwd)"/cowrie.cfg.dist "$(pwd)"/cowrievolumes/$CONTAINER_NAME/cowrie.$
                cp "$(pwd)"/cowrie.log "$(pwd)"/cowrievolumes/$CONTAINER_NAME/log/cowrie.l$
                cp "$(pwd)"/cowrie.json "$(pwd)"/cowrievolumes/$CONTAINER_NAME/log/cowrie.$
                sed -i 's/^\(sensor_name\s*=\s*\).*/\1'"$CONTAINER_NAME"'/' "$(pwd)"/cowri$

                docker create --name $CONTAINER_NAME --cap-add=NET_ADMIN \
                        -p 2222:2222 -p 2223:2223 \
                        -v "$(pwd)"/cowrievolumes/$CONTAINER_NAME/dl:/cowrie/cowrie-git/dl$
                        -v "$(pwd)"/cowrievolumes/$CONTAINER_NAME/log:/cowrie/cowrie-git/l$
                        -v "$(pwd)"/cowrievolumes/$CONTAINER_NAME/data:/cowrie/cowrie-git/$
                        cowrie:latest
                docker cp "$(pwd)"/cowrievolumes/$CONTAINER_NAME/cowrie.cfg router:/cowrie$
                docker network connect dmz $CONTAINER_NAME --ip "10.0.0.254"
                docker start $CONTAINER_NAME
        fi
}


check_container_exists(){
	exists=$( sudo docker container ls -a | grep '$CONTAINER_NAME' )
	if [ "$exists" == "$CONTAINER_NAME" ]
	then
		echo "A container named '$CONTAINER_NAME' already exists"
		exit 2
        else
                echo "Namecheck passed for $CONTAINER_NAME"
        fi
}

help() {
        echo "Script for launching a dockerised cowrie honeynet."
        echo "Usage: ./do_honeypot.sh <COMMAND> <CONTAINER_NAME>"
        echo "COMMANDS: "
        echo "          1. build - builds cowrie image and creates DMZ network with router$
        echo "          2. create - create a honeypot given a unique name. "
        echo "          3. exec - execute the container, displaying a bash shell inside th$
        echo "          4. start - start the container. "
        echo "          5. stop - stop the container. "
        echo "          6. remove - remove the container. "
        echo "          7. create_dmz_net - create a dmz net with a router."
        echo "Honeypot directories are preserved after removal of containers. Any deletion$
}
main


