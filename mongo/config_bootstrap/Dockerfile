FROM mongo:4.2

ENV REPLICATION_NODES=${REPLICATION_NODES}
ENV REPL_SET=${REPL_SET}
ENV KEY_FILE=${KEY_FILE:-/etc/secrets-volume/internal-auth-mongodb-keyfile}
ENV DB_ROOT=${DB_ROOT:-/data/configdb}

COPY init.sh /init.sh
USER root
RUN chmod +x /init.sh
ENTRYPOINT "/init.sh"
