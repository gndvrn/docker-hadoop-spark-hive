#!/bin/bash

function addProperty() {
    local path=$1
    local name=$2
    local value=$3

    if [[ -f ${path} ]]; then
        local entry="<property><name>$name</name><value>${value}</value></property>"
        local escapedEntry=$(echo ${entry} | sed 's/\//\\\//g')

        sed -i "/<\/configuration>/ s/.*/${escapedEntry}\n&/" ${path}

        echo "Added property ${name}=${value} to the file '${path}'."
    else
        echo "Unable to add property ${name}=${value}. The file '${path}' in not found."
    fi
}

function configure() {
    local path=$1
    local module=$2
    local envPrefix=$3

    if [[ -f ${path} ]]; then

        echo "Configuring $module"

        for c in `printenv | perl -sne 'print "$1 " if m/^${envPrefix}_(.+?)=.*/' -- -envPrefix=${envPrefix}`; do
            local name=`echo ${c} | perl -pe 's/___/-/g; s/__/_/g; s/_/./g'`
            local var="${envPrefix}_${c}"
            local value=${!var}

            echo " - Setting $name=$value"
            addProperty ${path} ${name} "$value"

            echo " - Un-setting ${var}"
            unset ${var}
        done

    else
        echo "Unable to configure module ${module}. The file '${path}' in not found."
    fi
}

configure ${HADOOP_CONF_DIR}/core-site.xml core CORE_CONF
configure ${HADOOP_CONF_DIR}/hdfs-site.xml hdfs HDFS_CONF
configure ${HADOOP_CONF_DIR}/yarn-site.xml yarn YARN_CONF
configure ${HADOOP_CONF_DIR}/mapred-site.xml mapred MAPRED_CONF
configure ${HADOOP_CONF_DIR}/hive-site.xml hive HIVE_SITE_CONF
configure ${HIVE_CONF_DIR}/hive-site.xml hive HIVE_SITE_CONF

exec $@
