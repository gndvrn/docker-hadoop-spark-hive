FROM hadoop-core:latest

LABEL platform="dev-hadoop-hive"

ENV HADOOP_HOME=/opt/hadoop

ENV HDFS_CONF_dfs_datanode_data_dir=file:///hadoop/dfs/data
RUN mkdir -p /hadoop/dfs/data
VOLUME /hadoop/dfs/data

COPY run.sh /run.sh
RUN chmod a+x /run.sh

# # datanode ui
EXPOSE 9864

CMD ["/run.sh"]
