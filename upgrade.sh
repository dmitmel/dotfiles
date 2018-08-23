#!/usr/bin/env bash

git pull --rebase --stat origin master
git submodule update --init --recursive --remote
