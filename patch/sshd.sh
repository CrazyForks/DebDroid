#!/bin/bash

# Check if the user has root permissions 
if [ "$(id -u)" -ne 0 ]; then
    echo "$0: Missing required super-user permisions."
    exit 1
fi

# Creates the runtime sshd directory
mkdir -p /run/sshd
