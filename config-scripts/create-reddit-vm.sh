#!/bin/bash

gcloud compute instances create new-reddit-app \
  --boot-disk-size=10GB \
  --image=reddit-full-1569577730 \
  --machine-type=g1-small \
  --tags puma-server \
  --restart-on-failure 
