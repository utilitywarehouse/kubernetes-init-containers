FROM mongo:4.2

ENV ADMIN_USERNAME=${ADMIN_USERNAME:-admin}
ENV ADMIN_PASSWORD=${ADMIN_PASSWORD}
ENV EXPORTER_USERNAME=${EXPORTER_USERNAME:-exporter}
ENV EXPORTER_PASSWORD=${EXPORTER_PASSWORD}
ENV MONGOLIZER_USERNAME=${MONGOLIZER_USERNAME:-mongolizer}
ENV MONGOLIZER_PASSWORD=${MONGOLIZER_PASSWORD}
ENV APP_USERNAME=${APP_USERNAME:-app}
ENV APP_PASSWORD=${APP_PASSWORD}
ENV APP_DB=${APP_DB:-app}
ENV REPLICATION_NODES=${REPLICATION_NODES}
ENV MASTER_NODE=${MASTER_NODE}
ENV REPL_SET=${REPL_SET}
ENV KEY_FILE=${KEY_FILE:-/etc/secrets-volume/internal-auth-mongodb-keyfile}
ENV DB_ROOT=${DB_ROOT:-/data/db}
ENV SKIP_BOOTSTRAP=${SKIP_BOOTSTRAP:-false}

COPY init.sh /init.sh
USER root
RUN chmod +x /init.sh

ENTRYPOINT "/init.sh"
