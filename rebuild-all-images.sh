#!/bin/bash

echo "Removing image with label platform=dev-hadoop-hive..."
docker rm $(docker ps -aq)
docker rmi $(docker images --filter="label=platform=dev-hadoop-hive")
echo "Removing image done."

echo "Building hadoop core image..."
docker build --no-cache -t hadoop-core:latest -f ./hadoop-core/Dockerfile .
echo "Done."

echo "Building hadoop name node image..."
docker build --no-cache -t hadoop-namenode:latest ./hadoop-namenode
echo "Done."

echo "Building hadoop data node image..."
docker build --no-cache -t hadoop-datanode:latest ./hadoop-datanode
echo "Done."

echo "Building hadoop resource manager image..."
docker build --no-cache -t hadoop-resourcemanager:latest ./hadoop-resourcemanager
echo "Done."

echo "Building hadoop node manager image..."
docker build --no-cache -t hadoop-nodemanager:latest ./hadoop-nodemanager
echo "Done."

echo "Building hive+hiveserver image..."
docker build --no-cache -t hadoop-hive:latest -f ./hadoop-hive/Dockerfile .
echo "Done."

echo "Building spark-yarn-jupyter image..."
docker build --no-cache -t spark-yarn:latest -f ./spark-yarn/Dockerfile .
echo "Done."