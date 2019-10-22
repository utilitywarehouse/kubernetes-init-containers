FROM mongo:4.2

ENV USERNAME=MONGO_HOST=${MONGO_HOST:-localhost} \
	     MONGO_PORT=${MONGO_PORT:-27017} \
	     USER_DB=${USER_DB:-testdb} \
	     ADMIN_DB=${ADMIN_DB:-admin} \
	     PASSWORD=${PASSWORD:-test_role_password} \
	     USERNAME=${USERNAME:-test_role_username} \
	     COLLECTION=${COLLECTION:-router-configurations} \
	     INDEXES=${INDEXES:-"[]"}
COPY init.sh /init.sh
USER root
RUN chmod +x /init.sh
ENTRYPOINT ["/bin/sh", "-c"]
CMD ["/init.sh"]
