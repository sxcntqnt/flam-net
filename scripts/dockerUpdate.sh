#!/bin/bash

#update all docker hyperledger images

podman images | grep -v "hyperledger|fabric" | awk '{print $1}' | xargs -n1 podman pull
