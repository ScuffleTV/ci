#!/bin/bash

clickhouse() {

    local backup_query="BACKUP ALL TO S3('${S3_ENDPOINT}/${S3_BUCKET}/${OUTPUT_FILE}.tar.gz', '${AWS_ACCESS_KEY_ID}', '${AWS_SECRET_ACCESS_KEY}');"

    if [ -n "$EXTRA_ARGS" ]; then
        backup_query="${backup_query} ${EXTRA_ARGS}"
    fi

    # if user and password user:password otherwise either one
    local user_info=""
    if [ -n "$DB_USER" ] && [ -n "$DB_PASSWORD" ]; then
        user_info="${DB_USER}:${DB_PASSWORD}@"
    elif [ -n "$DB_USER" ]; then
        user_info="${DB_USER}@"
    elif [ -n "$DB_PASSWORD" ]; then
        user_info="${DB_PASSWORD}@"
    fi

    or_default "DB_PORT" "8123"

    log "INFO" "Starting ClickHouse backup"

    invoke bash -c "echo \"$backup_query\" | curl \"http://${user_info}${DB_HOST}:${DB_PORT}/?\" --data-binary @- --fail-with-body"
}

clickhouse "$@"
