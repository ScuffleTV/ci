#!/bin/bash

mongodb() {
    local output_file="${TMP_DIR}/${OUTPUT_FILE}.tar.gz"

    or_default "DB_PORT" "27017"

    local args=(
        "--host=$DB_HOST"
        "--port=$DB_PORT"
        "--archive=$output_file"
        "--gzip"
    )

    if [ -n "$DB_USER" ] && [ -n "$DB_PASSWORD" ]; then
        args+=(
            "--username=$DB_USER"
            "--password=$DB_PASSWORD"
        )
    fi

    if [ -n "$EXTRA_ARGS" ]; then
        args+=("$EXTRA_ARGS")
    fi

    log "INFO" "Starting MongoDB backup"

    invoke mongodump "${args[@]}"

    s3_upload "$output_file"
}

mongodb "$@"
