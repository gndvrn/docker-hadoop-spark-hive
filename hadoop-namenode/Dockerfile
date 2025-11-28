FROM hadoop-core:latest

LABEL platform="dev-hadoop-hive"

COPY run.sh /run.sh
RUN chmod a+x /run.sh

# namenode ui
EXPOSE 9870

CMD ["/run.sh"]
