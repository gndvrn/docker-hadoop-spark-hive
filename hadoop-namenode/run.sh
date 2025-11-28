#!/bin/bash

export HADOOP_OPTS="$HADOOP_OPTS --add-opens java.base/java.lang=ALL-UNNAMED"
export HADOOP_OPTS="$HADOOP_OPTS --add-opens java.base/java.lang.reflect=ALL-UNNAMED"

if [ -d "/tmp/hadoop-root/dfs/name/current" ]; then
    echo "Namenode formatted!"
else
    echo "Formatting Namenode!"
    ${HADOOP_HOME}/bin/hdfs --config ${HADOOP_CONF_DIR} namenode -format ${CLUSTER_NAME} -force -nonInteractive
fi

echo "Starting Namenode!"
${HADOOP_HOME}/bin/hdfs --config ${HADOOP_CONF_DIR} namenode
