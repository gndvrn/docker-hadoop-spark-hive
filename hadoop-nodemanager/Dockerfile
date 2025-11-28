FROM hadoop-core:latest

LABEL platform="dev-hadoop-hive"

RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip

COPY run.sh /run.sh
RUN chmod a+x /run.sh

# node manager UI
EXPOSE 8042

CMD ["/run.sh"]
