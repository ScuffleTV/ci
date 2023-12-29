#!/bin/bash
set -e

# Extract the first argument as the command.
cmd=$1

# Remove the first argument from the list.
shift

# Also accept args from the environment.
if [ -n "$ARGS" ]; then
    # Use eval to execute the command with INPUT_ARGS.
    # The exec replaces the current shell with the command.
    # Quoting is important to handle spaces and special characters.
    eval "exec $cmd $ARGS"
else
    # If INPUT_ARGS is not set, use exec to replace the shell
    # with the command and the direct script arguments.
    exec "$cmd" "$@"
fi
