#!/bin/bash

cd 10.network_setup
./setup-network.sh create

cd wwwapp
./wwwapp-podman.sh clean
./wwwapp-podman.sh build
./wwwapp-podman.sh start

./wwwapp-podman.sh status
./wwwapp-podman.sh network-info