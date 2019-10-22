FROM mongo:4.2

ENV USERNAME=${USERNAME:-test_role_username} \
	     PASSWORD=${PASSWORD:-test_role_password} \
	     ADMIN_DB=${ADMIN_DB:-admin} \
	     USER_DB=${USER_DB:-testdb} \
	     ADMIN_USERNAME=${ADMIN_USERNAME:-testuser} \
	     ADMIN_PASSWORD=${ADMIN_PASSWORD:-testpassword} \
	     MONGO_HOST=${MONGO_HOST:-localhost} \
	     MONGO_PORT=${MONGO_PORT:-27017}

COPY init.sh /init.sh
USER root
RUN chmod +x /init.sh
ENTRYPOINT "/init.sh"
