#!/bin/bash

set -euo pipefail

cd "$(dirname "$(realpath "$0")")"

source ./utils.sh

# Default values
VERBOSE=${VERBOSE:-0}
DEBUG=${DEBUG:-0}
TMP_DIR=${TMP_DIR:-}
S3_BUCKET=${S3_BUCKET:-}
S3_ENDPOINT=${S3_ENDPOINT:-}
AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID:-}
AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY:-}
DB_HOST=${DB_HOST:-}
DB_PORT=${DB_PORT:-}
DB_USER=${DB_USER:-}
DB_PASSWORD=${DB_PASSWORD:-}
EXTRA_ARGS=${EXTRA_ARGS:-}
COMMAND=${COMMAND:-}
OUTPUT_PREFIX=${OUTPUT_PREFIX:-}
OUTPUT_DATE=${OUTPUT_DATE:-}
OUTPUT_FILE=${OUTPUT_FILE:-}

parse_args "$@"

or_default TMP_DIR "/tmp"
or_default S3_ENDPOINT "https://${AWS_REGION:-us-east-1}.amazonaws.com"
or_default OUTPUT_DATE "$(date +%Y%m%d%H%M%S)"
or_default OUTPUT_PREFIX "${COMMAND}_"
or_default OUTPUT_FILE "${OUTPUT_PREFIX}${OUTPUT_DATE}"
or_default DB_HOST "localhost"


# if debug print out the variables
if [ "$DEBUG" -eq 1 ]; then
    args=(
        --verbose
        --debug
        --tmp-dir=\"$TMP_DIR\"
        --s3-bucket=\"$S3_BUCKET\"
        --s3-endpoint=\"$S3_ENDPOINT\"
        --aws-access-key-id=\"$AWS_ACCESS_KEY_ID\"
        --aws-secret-access-key=\"$AWS_SECRET_ACCESS_KEY\"
        --output-prefix=\"$OUTPUT_PREFIX\"
        --db-host=\"$DB_HOST\"
        --db-port=\"$DB_PORT\"
        --db-user=\"$DB_USER\"
        --db-password=\"$DB_PASSWORD\"
        --extra-args=\"$EXTRA_ARGS\"
        $COMMAND
    )

    log "DEBUG" "${args[*]}"
fi
    

case "$COMMAND" in
    postgresql)
        . ./postgresql.sh
        ;;
    redis)
        . ./redis.sh
        ;;
    mongodb)
        . ./mongodb.sh
        ;;
    clickhouse)
        . ./clickhouse.sh
        ;;
esac
