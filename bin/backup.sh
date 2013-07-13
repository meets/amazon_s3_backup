#!/bin/bash

# ** バックアップコマンドの発行 **


self=`readlink -f ${0}`
current_dir=`dirname $self`

cd "$current_dir/.."

bundle exec rake backup

