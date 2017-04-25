from mongo:3.4

env USERNAME=MONGO_HOST=${MONGO_HOST:-localhost} \
	     MONGO_PORT=${MONGO_PORT:-27017} \
	     USER_DB=${USER_DB:-testdb} \
	     ADMIN_DB=${ADMIN_DB:-admin} \
	     PASSWORD=${PASSWORD:-test_role_password} \
	     USERNAME=${USERNAME:-test_role_username} \
	     COLLECTION=${COLLECTION:-router-configurations} \
	     INDEX_FIELD=${INDEX_FIELD:-serialnumber} \
	     INDEX_NAME=${INDEX_NAME:-serialnumber_1} \
	     FILTER_EXPRESSION=${FILTER_EXPRESSION:-"deleted: false"}

copy init.sh /init.sh
user root
run chmod +x /init.sh
entrypoint "/init.sh"
