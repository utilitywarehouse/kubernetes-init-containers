FROM mongo:4.2

ENV USERNAME=${USERNAME:-testuser}
ENV PASSWORD=${PASSWORD:-testpassword}
ENV ADMIN_DB=${ADMIN_DB:-admin}
ENV DB_ROOT=${DB_ROOT:-/data/db}

COPY init.sh /init.sh
USER root
RUN chmod +x /init.sh
ENTRYPOINT "/init.sh"
