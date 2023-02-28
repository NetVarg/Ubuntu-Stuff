#!/bin/bash

# Debugging a bash script.


# All executed commands are printed to the terminal.
# Write log to /tmp/bash.log file with line numbers.
exec > >(tee -i /tmp/bash.log)
exec 2>&1
PS4='$LINENO: '
set -x

echo "Here runs your code..."

# Example output
for i in 1 2 3
do
   echo "Debug $i output."
done

# Disable debugging
set +x
exit 0