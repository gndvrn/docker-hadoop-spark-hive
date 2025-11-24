#!/bin/bash
set -e

export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))
export PATH=$JAVA_HOME/bin:$PATH
echo "JAVA_HOME dynamically set to $JAVA_HOME"
java -version

echo "Hive schema checking!"

if $HIVE_HOME/bin/schematool -dbType postgres -info | grep -q "Schema version"; then
    echo "Hive schema already initialized."
else
    echo "Initializing Hive schema..."
    $HIVE_HOME/bin/schematool -dbType postgres -initSchema || echo "Schema already initialized or encountered an error"
fi

# Load NYC Taxi data to HDFS if it hasn't been loaded yet
if [ ! -f /tmp/nyc_taxi_data_loaded ]; then
    echo "Loading NYC Taxi data to HDFS..."
    /load_nyc_taxi_data.sh
    if [ $? -eq 0 ]; then
        touch /tmp/nyc_taxi_data_loaded
        echo "NYC Taxi data successfully loaded to HDFS"
    else
        echo "Error loading NYC Taxi data to HDFS"
    fi
else
    echo "NYC Taxi data already loaded to HDFS"
fi

# Start Hive Metastore & Hive Server 2
hive --service metastore & hive --service hiveserver2