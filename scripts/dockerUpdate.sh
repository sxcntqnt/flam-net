#!/bin/bash

#update all docker hyperledger images

docker images |grep -v "hyperledger|fabric" |awk '{print $1}' |docker pull
