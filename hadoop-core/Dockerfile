FROM debian:bullseye-slim

LABEL platform="dev-hadoop-hive"

ARG TIMEZONE=Europe/Moscow
RUN ln -snf /usr/share/zoneinfo/$TIMEZONE /etc/localtime && echo $TIMEZONE > /etc/timezone

# Install required packages
RUN apt-get update && apt-get install -y \
    ssh \
    openjdk-17-jdk \
    wget \
    unzip \
    nano \
    sudo \
    netcat-openbsd

RUN mkdir /var/run/sshd
RUN service ssh start

ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-arm64
ENV PATH="${JAVA_HOME}/bin:${PATH}"

RUN ssh-keygen -q -t rsa -N "" -f ~/.ssh/id_rsa && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && \
    chmod 0600 ~/.ssh/authorized_keys

ENV HADOOP_HOME=/opt/hadoop
ENV HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
ENV PATH=$HADOOP_HOME/bin/:$PATH

ENV HIVE_HOME=/opt/hive
ENV PATH=${HIVE_HOME}/bin:$PATH
ENV HIVE_CONF_DIR=${HIVE_HOME}/conf

ARG HADOOP_VERSION=3.4.0
ARG TMP_DIR=/tmp/hadoop

RUN mkdir -pv ${TMP_DIR} \
    && mkdir -pv ${HADOOP_HOME}

# RUN wget https://downloads.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz -P ${TMP_DIR}

COPY downloads/hadoop-3.4.0.tar.gz ${TMP_DIR}/

RUN tar -xzf ${TMP_DIR}/hadoop-3.4.0.tar.gz -C ${HADOOP_HOME} --strip-components=1 \
    && rm -rf ${TMP_DIR}/hadoop-3.4.0.tar.gz \
    && rm -rf ${HADOOP_HOME}/share/doc

# Copy settings file and entrypoint script
COPY settings.env /settings.env
COPY hadoop-core/entrypoint.sh /entrypoint.sh
RUN chmod a+x /entrypoint.sh

# Source the settings and pre-generate configurations during build
RUN set -a && . /settings.env && set +a && \
    /entrypoint.sh echo "Configurations pre-generated during build" && \
    # Clean up settings file after build
    rm /settings.env
