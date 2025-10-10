#!/bin/bash

mkdir -p lib
gcc -fPIC -shared -o lib/librandom.so src/librandom.c
