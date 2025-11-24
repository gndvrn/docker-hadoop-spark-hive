FROM hadoop-core:latest

LABEL platform="dev-hadoop-hive"

COPY run.sh /run.sh
RUN chmod a+x /run.sh

# node manager UI
EXPOSE 8042

CMD ["/run.sh"]
