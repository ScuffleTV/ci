#!/bin/bash

postgresql() {
    local output_file="${TMP_DIR}/${OUTPUT_FILE}.sql"

    or_default "DB_PORT" "5432"
    or_default "DB_USER" "postgres"

    local args=(
        --host="$DB_HOST"
        --port="$DB_PORT"
        --file="$output_file"
        --username="$DB_USER"
        --no-password
    )

    if [ -n "$EXTRA_ARGS" ]; then
        args+=($EXTRA_ARGS)
    fi

    log "INFO" "Starting PostgreSQL backup"

    PGPASSWORD=$DB_PASSWORD invoke pg_dumpall ${args[@]}

    # GZIP the output file
    gzip "$output_file"

    s3_upload "$output_file.gz"
}

postgresql "$@"
