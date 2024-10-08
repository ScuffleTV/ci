#!/bin/bash

redis() {
    local output_file="${TMP_DIR}/${OUTPUT_FILE}.rdb"

    or_default "DB_PORT" "6379"

    # Create a Redis backup using `redis-cli`
    local args=(
        -h "$DB_HOST"
        -p "$DB_PORT"
        --rdb "$output_file"
    )

    if [ -n "$DB_PASSWORD" ]; then
        args+=(-a "$DB_PASSWORD")
    fi

    args+=("$EXTRA_ARGS")

    log "INFO" "Starting Redis backup"

    invoke redis-cli "${args[@]}"
    invoke gzip "$output_file"

    s3_upload "$output_file.gz"
}

redis "$@"
