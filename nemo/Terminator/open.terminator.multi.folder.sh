#!/bin/bash

# Check if any terminator already open.
pgrep terminator >/dev/null 2>&1
if [$? -eq 0]; then
    # Start a Terminator with the first folder.
    terminator --working-directory="$1" >/dev/null 2>&1 &

    # Wait a moment until terminator is started.
    # If you rather have a slow PC, increase the sleep time
    sleep .1
    shift
fi
for folder in "$@"; do
    terminator --new-tab --working-directory="$folder" >/dev/null 2>&1 &
done
