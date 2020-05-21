
FROM postgres:12.1-alpine

ENV ADMIN_USERNAME=${APP_USERNAME:-postgres}
ENV EXPORTER_USERNAME=${EXPORTER_USERNAME:-exporter}
ENV EXPORTER_PASSWORD=${EXPORTER_PASSWORD}
ENV APP_USERNAME=${APP_USERNAME:-app}
ENV APP_PASSWORD=${APP_PASSWORD}
ENV DB_ROOT=${DB_ROOT:-/var/lib/postgresql/data}
ENV DB_NAME=${DB_NAME}
COPY init.sh /docker-entrypoint-initdb.d/

COPY init-check.sh /init-check.sh
USER root
RUN chmod +x /init-check.sh

ENTRYPOINT "/init-check.sh"