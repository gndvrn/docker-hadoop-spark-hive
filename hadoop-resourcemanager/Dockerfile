FROM hadoop-core:latest

LABEL platform="dev-hadoop-hive"

COPY run.sh /run.sh
RUN chmod a+x /run.sh

# resource manager UI
EXPOSE 8088

CMD ["/run.sh"]
