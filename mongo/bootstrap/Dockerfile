from mongo:3.4

env USERNAME=${USERNAME:-testuser}
env PASSWORD=${PASSWORD:-testpassword}
env ADMIN_DB=${ADMIN_DB:-admin}
env DB_ROOT=${DB_ROOT:-/data/db}

copy init.sh /init.sh
user root
run chmod +x /init.sh
entrypoint "/init.sh"
