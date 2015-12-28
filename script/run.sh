#! /bin/bash

set -e

source /usr/local/rvm/scripts/rvm

rails server -p 8080 -e production -d
