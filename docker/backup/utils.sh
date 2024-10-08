#!/bin/bash

log() {
    local log_level=$1
    shift
    local log_date=$(date "+%Y-%m-%d %H:%M:%S")
    local file=${BASH_SOURCE[1]##*/}
    local line=${BASH_LINENO[0]}

    case $log_level in
        DEBUG)
            if [ $VERBOSE != 1 ]; then
                return
            fi
            ;;
    esac

    echo "[$log_date] [$log_level] [$file:$line] $*"
}

usage() {
    echo "Usage: $0 <command> [OPTIONS]"
    echo
    echo "Options:"
    echo "  -h, --help"
    echo "  -v, --verbose"
    echo "  -d, --debug"
    echo "  --s3-bucket <bucket> (required or use S3_BUCKET)"
    echo "  --s3-endpoint <endpoint> (optional or use S3_ENDPOINT)"
    echo "  --aws-access-key-id <key> (required or use AWS_ACCESS_KEY_ID)"
    echo "  --aws-secret-access-key <key> (required or use AWS_SECRET_ACCESS_KEY)"
    echo "  --s3-prefix <prefix> (optional or use S3_PREFIX)"
    echo "  --db-host <host> (optional or use DB_HOST)"
    echo "  --db-port <port> (optional or use DB_PORT)"
    echo "  --db-user <user> (optional or use DB_USER)"
    echo "  --db-password <password> (optional or use DB_PASSWORD)"
    echo "  --extra-args <args> (optional or use EXTRA_ARGS)"
    echo
    echo "Commands:"
    echo "  postgresql"
    echo "  redis"
    echo "  mongodb"
    echo "  clickhouse"
    echo

    exit 1
}

set_option() {
    local var_name="$1"
    local value="$2"
    local option_name="$3"

    if [[ -n "${!var_name}" ]]; then
        echo "Error: Duplicate $option_name option"
        exit 1
    fi

    if [[ -z "$value" ]]; then
        echo "Error: $option_name requires an argument"
        exit 1
    fi

    local -n VAR="$var_name"
    VAR="$value"
}

parse_option() {
    local option="$1"
    local value="$2"

    case "$option" in
        --s3-bucket) set_option "S3_BUCKET" $value $option;;
        --s3-endpoint)  set_option "S3_ENDPOINT" $value $option;;
        --aws-access-key-id)  set_option "AWS_ACCESS_KEY_ID" $value $option;;
        --aws-secret-access-key)  set_option "AWS_SECRET_ACCESS_KEY" $value $option;;
        --s3-prefix) set_option "S3_PREFIX" $value $option;;
        --db-host)  set_option "DB_HOST" $value $option;;
        --db-port)  set_option "DB_PORT" $value $option;;
        --db-user)  set_option "DB_USER" $value $option;;
        --db-password)  set_option "DB_PASSWORD" $value $option;;
        --extra-args)  set_option "EXTRA_ARGS" $value $option;;
        *)
            echo "Unknown option: $option"
            exit 1
            ;;
    esac
}

# Parse options and subcommands
parse_args() {
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            -h|--help)
                usage
                ;;
            -v|--verbose)
                VERBOSE=1
                shift
                ;;
            -d|--debug)
                DEBUG=1
                VERBOSE=1
                shift
                ;;
            --*=*)  # Handle options in --opt=value format
                parse_option "${1%%=*}" "${1#*=}"
                shift
                ;;
            --*)
                parse_option "$1" "${2:-}"
                shift 2
                ;;
            *)
                if [[ -n "$COMMAND" ]]; then
                    echo "Unexpected argument: $1"
                    echo
                    usage
                    exit 1
                fi

                COMMAND="$1"
                shift
                ;;
        esac
    done

    if [[ -z "$COMMAND" ]]; then
        usage
        exit 1
    fi

    # Verify $COMMAND is a valid command
    if [[ ! "postgresql redis mongodb clickhouse" =~ $COMMAND ]]; then
        echo "Invalid command: $COMMAND"
        echo
        usage
        exit 1
    fi

    # Check required options
    if [[ -z "$S3_BUCKET" ]]; then
        errors+=("  --s3-bucket")
    fi
    if [[ -z "$AWS_ACCESS_KEY_ID" ]]; then
        errors+=("  --aws-access-key-id")
    fi
    if [[ -z "$AWS_SECRET_ACCESS_KEY" ]]; then
        errors+=("  --aws-secret-access-key")
    fi

    if [[ -n "${errors[*]}" ]]; then
        echo "Options required but not provided:"
        for error in "${errors[@]}"; do
            echo "$error"
        done
        echo
        usage
    fi
}

invoke() {
    log "DEBUG" "Invoking: $*"

    "$@"
}

s3_upload() {
    local file=$1
    # strip file from $OUTPUT_FILE
    local ext=${file/#"$TMP_DIR/$OUTPUT_FILE"}

    echo "ext: $ext"
    echo "file: $file"
    echo "OUTPUT_FILE: $OUTPUT_FILE"

    local args=(
        --endpoint-url "$S3_ENDPOINT"
        s3
        cp
        "$file"
        "s3://${S3_BUCKET}/${OUTPUT_FILE}${ext}"
    )

    log "INFO" "Uploading $file to s3://$S3_BUCKET/$OUTPUT_FILE${ext}"
    invoke aws "${args[@]}"

    if [ $? -eq 0 ]; then
        log "INFO" "Successfully uploaded $file to s3://${S3_BUCKET}/${OUTPUT_FILE}${ext}"
    else
        log "ERROR" "Failed to upload $file to s3://${S3_BUCKET}/${OUTPUT_FILE}${ext}"
        exit 1
    fi
}

or_default() {
    local var_name="$1"
    local default_value="$2"

    # if the variable is empty or unset, set it to the default value
    if [ -z "${!var_name}" ]; then
        local -n VAR=$var_name
        VAR="$default_value"
    fi    
}
