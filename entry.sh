#!/usr/bin/env bash

set -e

echo "Configuring mail..."
ansible-playbook  /usr/local/bin/main.yml -i localhost, --connection=local

# Create logging FIFO
mkfifo /dev/maillog

echo "Exec'ing $@"
exec "$@"