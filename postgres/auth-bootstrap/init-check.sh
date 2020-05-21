#!/bin/bash

set -x

# only continue if the database isn't already initialised
if [ -s "${DB_ROOT}/PG_VERSION" ]; then
    exit 0
fi

/usr/local/bin/docker-entrypoint.sh
