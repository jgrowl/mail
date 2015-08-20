#!/usr/bin/env bash

# exit cleanly
trap "{ /usr/sbin/service $1 stop; }" EXIT

/usr/sbin/service $1 start

# don't exit
sleep infinity