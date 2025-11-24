FROM hadoop-core:latest

LABEL platform="dev-hadoop-hive"

RUN apt-get update && apt-get install -y postgresql-client-13

ARG HIVE_DOWNLOAD_DIR=/tmp/hive
ARG HIVE_VERSION=4.1.0
ARG POSTGRESQL_JDBC_VERSION=42.2.23

# RUN wget https://downloads.apache.org/hive/hive-${HIVE_VERSION}/apache-hive-${HIVE_VERSION}-bin.tar.gz -O /tmp/hive.tar.gz
COPY downloads/apache-hive-4.1.0-bin.tar.gz /tmp/hive.tar.gz

RUN mkdir -pv ${HIVE_DOWNLOAD_DIR}

RUN tar -xvf /tmp/hive.tar.gz -C ${HIVE_DOWNLOAD_DIR} --strip-components=1 \
    && mv -v ${HIVE_DOWNLOAD_DIR} /opt \
    && rm -rfv /tmp/hive.tar.gz \
    && rm -rfv ${HIVE_HOME}/lib/postgresql-*.jre*.jar

RUN wget https://jdbc.postgresql.org/download/postgresql-${POSTGRESQL_JDBC_VERSION}.jar -O ${HIVE_HOME}/lib/postgresql-jdbc.jar


EXPOSE 10000 10002

COPY hadoop-hive/run.sh /run.sh
RUN chmod a+x /run.sh

# NYC Taxi data loading script
COPY hadoop-hive/load_nyc_taxi_data.sh /load_nyc_taxi_data.sh
RUN chmod +x /load_nyc_taxi_data.sh

# Command to run Hive
COPY hadoop-core/entrypoint.sh /entrypoint.sh
RUN chmod a+x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/run.sh"]











