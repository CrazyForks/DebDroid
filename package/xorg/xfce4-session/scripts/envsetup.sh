#!/bin/sh

export CFLAGS="-I$PWD/include"
export LDFLAGS="-L$PWD/lib"
export PKG_CONFIG_PATH="$PWD/pkg-config"
