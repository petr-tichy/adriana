#! /bin/bash

set -e

source /usr/local/rvm/scripts/rvm

rvm use ruby-2.0.0-p247

rails server -p 8080 -e production -d