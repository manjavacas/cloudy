#!/bin/bash

if [ -z "$1" ]; then
  echo "Error: argumento no introducido."
  exit 1
fi

MACHINE_NAME="$1"

sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y python3 python3-pip

pip3 install numpy

REPO_URL="https://github.com/manjavacas/cloudexec.git"
git clone $REPO_URL

cd cloudexec/scripts

python3 foo.py "$MACHINE_NAME" > out.txt
