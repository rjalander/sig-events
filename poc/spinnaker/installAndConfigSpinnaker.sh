#!/bin/bash

## This script is used for the following actions
## 1. Install halyard and configure with kubernetes 
## 2. Install Minio Server as service in k8s cluster and configure as storage service for spinnaker
## 3. Configure kubernetes account with spinnaker
## 4. Install spinnaker using halyard command
##
##
##


BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

## Declare variables

## Helper functions

########
## Main
#######

