FROM hadoop-core:latest

LABEL platform="dev-hadoop-hive"

COPY run.sh /run.sh
RUN chmod a+x /run.sh

# datanode ui
EXPOSE 9864

CMD ["/run.sh"]
