#!/bin/sh

REPO="$1"

mkdir "$REPO"
git init --bare "$REPO"
chown -R gitproxy: "$REPO"

