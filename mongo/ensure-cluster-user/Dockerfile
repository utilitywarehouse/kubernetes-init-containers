FROM mongo:3.4

ENV MONGO_NODES=${MONGO_NODES:-localhost:27017} \
    ADMIN_USERNAME=${ADMIN_PASSWORD:-admin} \
    ADMIN_PASSWORD=${ADMIN_PASSWORD} \
    ADMIN_DB=${ADMIN_DB:-admin} \
    MONGO_USERNAME=${MONGO_USERNAME:-app} \
    MONGO_PASSWORD=${MONGO_PASSWORD} \
    MONGO_DB=${MONGO_DB:-app} \
    ROLE=${ROLE:-read} 

COPY ensure_user.sh /ensure_user.sh
USER root
RUN chmod +x /ensure_user.sh
ENTRYPOINT "/ensure_user.sh"