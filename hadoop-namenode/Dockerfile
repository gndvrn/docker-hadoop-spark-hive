FROM hadoop-core:latest

LABEL platform="dev-hadoop-hive"

ENV HADOOP_HOME=/opt/hadoop

ENV HDFS_CONF_dfs_namenode_name_dir=file:///hadoop/dfs/name
RUN mkdir -p /hadoop/dfs/name
VOLUME /hadoop/dfs/name

COPY run.sh /run.sh
RUN chmod a+x /run.sh

# namenode ui
EXPOSE 9870

CMD ["/run.sh"]
