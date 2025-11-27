#!/bin/bash
set -e

echo "Starting NYC Taxi data download and HDFS upload (uncompressed)..."

HDFS_DATA_PATH="/user/hive/warehouse/nyc_taxi_data"

echo "Creating HDFS directory: $HDFS_DATA_PATH"
$HADOOP_HOME/bin/hdfs dfs -mkdir -p $HDFS_DATA_PATH

for i in {0..2}; do
  echo "Processing file $i/2..."
  LOCAL_GZ="/tmp/trips_$i.gz"
  LOCAL_CSV="/tmp/trips_$i.csv"
  FILE_URL="https://datasets-documentation.s3.eu-west-3.amazonaws.com/nyc-taxi/trips_$i.gz"

  if [ -f "$LOCAL_GZ" ]; then
      echo "File $LOCAL_GZ already exists — skipping download."
  else
      echo "Downloading $FILE_URL..."
      wget -q "$FILE_URL" -O "$LOCAL_GZ"
  fi

  echo "Decompressing trips_$i.gz..."
  zcat "$LOCAL_GZ" > "$LOCAL_CSV"

  echo "Uploading trips_$i.csv to HDFS..."
  $HADOOP_HOME/bin/hdfs dfs -put "$LOCAL_CSV" "$HDFS_DATA_PATH/"

  rm "$LOCAL_CSV"
  echo "Successfully uploaded trips_$i.csv"
done

echo "NYC Taxi data successfully loaded to HDFS at $HDFS_DATA_PATH"
$HADOOP_HOME/bin/hdfs dfs -du -h $HDFS_DATA_PATH
$HADOOP_HOME/bin/hdfs dfs -ls $HDFS_DATA_PATH