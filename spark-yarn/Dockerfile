FROM hadoop-core:latest

LABEL platform="dev-hadoop-hive"

RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip

# Set Spark version and download URL
ENV SPARK_VERSION=3.5.7
ENV SPARK_HOME=/opt/spark
ENV SPARK_CONF_DIR=$SPARK_HOME/conf
ENV PATH=$SPARK_HOME/bin/:$PATH

ENV YARN_CONF_DIR=${HADOOP_CONF_DIR}

# Set SPARK_DIST_CLASSPATH to include Hadoop dependencies
RUN export SPARK_DIST_CLASSPATH=$(${HADOOP_HOME}/bin/hadoop classpath) && \
    echo "SPARK_DIST_CLASSPATH=$SPARK_DIST_CLASSPATH" >> /etc/environment
ENV SPARK_DIST_CLASSPATH=${SPARK_DIST_CLASSPATH}

# Create Spark directories
RUN mkdir -pv ${SPARK_HOME}

# Download and install Spark
ARG TMP_DIR=/tmp/spark
RUN mkdir -pv ${TMP_DIR}

# Copy Spark distribution from downloads folder
COPY downloads/spark-${SPARK_VERSION}-bin-hadoop3.tgz ${TMP_DIR}/
RUN tar -xzf ${TMP_DIR}/spark-${SPARK_VERSION}-bin-hadoop3.tgz -C ${SPARK_HOME} --strip-components=1 \
    && rm -rf ${TMP_DIR}/spark-${SPARK_VERSION}-bin-hadoop3.tgz

# Copy and install pyspark from local file
COPY downloads/pyspark-3.5.7.tar.gz /tmp/pyspark.tar.gz
RUN pip3 install /tmp/pyspark.tar.gz && rm -rf /tmp/pyspark.tar.gz

# Install Jupyter notebook
RUN pip3 install jupyter

# Create Spark configuration directory
RUN mkdir -p $SPARK_CONF_DIR

# Create directories for Spark event logs and local directories
RUN mkdir -p /tmp/spark-events

# Expose Jupyter port
EXPOSE 8888

WORKDIR $SPARK_HOME

# Copy Jupyter startup script
COPY spark-yarn/start-jupyter.sh /opt/scripts/start-jupyter.sh
RUN chmod +x /opt/scripts/start-jupyter.sh

CMD ["/opt/scripts/start-jupyter.sh"]