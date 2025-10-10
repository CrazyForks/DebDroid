#!/bin/bash

mkdir -p lib
gcc -fPIC -shared -o lib/libarc4random.so src/libarc4random.c

