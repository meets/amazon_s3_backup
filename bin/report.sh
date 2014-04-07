#!/bin/bash

self=`readlink -f ${0}`
current_dir=`dirname $self`

cd "$current_dir/.."

bundle exec rake report
