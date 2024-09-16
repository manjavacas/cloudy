#!/usr/bin/env bash

for i in $(seq 1 2); do
  gcloud compute instances create "vm-experiment-$i" \
    --zone=europe-southwest1-b \
    --machine-type=e2-medium  \
    --image-family=ubuntu-2004-lts \
    --image-project=ubuntu-os-cloud \
    --metadata startup-script='#! /bin/bash
      sudo apt-get update
      sudo apt-get install -y python3-pip
      pip install numpy
      git clone https://github.com/manjavacas/cloudexec.git
      cd cloudexec/scripts
      python3 foo.py "Joe" > output.txt'
done