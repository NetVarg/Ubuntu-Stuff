#!/bin/bash

for folder in "$@"; do
    terminator --new-tab --working-directory="$folder" >/dev/null 2>&1 &
done
