#!/bin/bash
set -e

echo "Starting NYC Taxi data download and HDFS upload (uncompressed)..."

# Define the HDFS path where the data will be stored
HDFS_DATA_PATH="/user/hive/warehouse/nyc_taxi_data"

# Create the directory in HDFS if it doesn't exist
echo "Creating HDFS directory: $HDFS_DATA_PATH"
$HADOOP_HOME/bin/hdfs dfs -mkdir -p $HDFS_DATA_PATH

# Download and upload each of the three data files
for i in {0..2}; do
  echo "Processing file $i/2..."
  FILE_URL="https://datasets-documentation.s3.eu-west-3.amazonaws.com/nyc-taxi/trips_$i.gz"
  
  echo "Downloading $FILE_URL..."
  wget -q $FILE_URL -O /tmp/trips_$i.gz
  
  echo "Decompressing trips_$i.gz using zcat..."
  zcat /tmp/trips_$i.gz > /tmp/trips_$i.csv
  
  echo "Uploading trips_$i.csv to HDFS..."
  $HADOOP_HOME/bin/hdfs dfs -put /tmp/trips_$i.csv $HDFS_DATA_PATH/
  
  # Clean up local files
  rm /tmp/trips_$i.gz
  rm /tmp/trips_$i.csv
  
  echo "Successfully uploaded trips_$i.csv"
done

echo "NYC Taxi data successfully loaded to HDFS at $HDFS_DATA_PATH"
echo "Total size in HDFS:"
$HADOOP_HOME/bin/hdfs dfs -du -h $HDFS_DATA_PATH

# List the files in the directory
echo "Files in $HDFS_DATA_PATH:"
$HADOOP_HOME/bin/hdfs dfs -ls $HDFS_DATA_PATH