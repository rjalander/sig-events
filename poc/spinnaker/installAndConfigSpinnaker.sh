#!/bin/bash

set -e -o pipefail

## This script is used for the following actions
## 1. Install halyard and verify the version 
## 2. Install Minio Server as service in k8s cluster and configure as storage service for spinnaker
## 3. Configure kubernetes account with spinnaker
## 4. Install spinnaker using halyard command
##
##
##


BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

## Declare variables
GIT_PATH_SIGEVENTS=~/sig-events

## functions
function installHelm() {
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    chmod 700 get_helm.sh
    ./get_helm.sh
    helm version > /dev/null
}

function installHalyard() {
    curl -O https://raw.githubusercontent.com/spinnaker/halyard/master/install/debian/InstallHalyard.sh
    sudo bash InstallHalyard.sh
    hal -v > /dev/null
}

function installSpinCLI () {
    curl -LO https://storage.googleapis.com/spinnaker-artifacts/spin/$(curl -s https://storage.googleapis.com/spinnaker-artifacts/spin/latest)/linux/amd64/spin
    chmod +x spin
    sudo mv spin /usr/local/bin/spin
    spin --version >> /dev/null
}

function installMinioService() {
    helm repo add minio https://helm.min.io/
    helm install my-release minio/minio
    echo "Sleep for 10Sec to initialize MINIO_END_POINT"
    sleep 10

    ACCESS_KEY=$(kubectl get secret -n default my-release-minio -o jsonpath="{.data.accesskey}" | base64 --decode)
    SECRET_KEY=$(kubectl get secret -n default my-release-minio -o jsonpath="{.data.secretkey}" | base64 --decode)
    MINIO_END_POINT=$(kubectl get endpoints my-release-minio -n default | grep my-release-minio | awk '{print $2}')
    echo "MINIO_END_POINT ==> $MINIO_END_POINT"

    echo $SECRET_KEY | \
         hal config storage s3 edit --endpoint http://$MINIO_END_POINT \
             --access-key-id $ACCESS_KEY \
             --secret-access-key

    hal config storage edit --type s3

    mkdir -p ~/.hal/default/profiles &&   touch ~/.hal/default/profiles/front50-local.yml
    echo 'spinnaker.s3.versioning: false' > ~/.hal/default/profiles/front50-local.yml
}

function configureK8SAccountWithSpinnaker() {
    hal config provider kubernetes enable
    K8S_ACCOUNT=poc-k8s-account
    hal config provider kubernetes account add $K8S_ACCOUNT \
        --provider-version v2 \
        --context $(kubectl config current-context)
    hal config deploy edit --type distributed --account-name $K8S_ACCOUNT
}

function installSpinnaker() {
    hal config version edit --version 1.26.6
    hal deploy apply

    kubectl delete svc spin-echo -n spinnaker
    mkdir -p ~/dev/spinnaker/echo
    git clone git@github.com:rjalander/echo.git -b cdevent_consume ~/dev/spinnaker/echo
    cd ~/dev/spinnaker/echo
    ln ~/.hal/default/staging/echo.yml ./echo.yml
    ln ~/.hal/default/staging/spinnaker.yml ./spinnaker.yml
    ./gradlew echo-web:installDist -x test && docker build -f Dockerfile.slim --tag localhost:5000/cdevents/spinnaker-echo-poc .
    docker push localhost:5000/cdevents/spinnaker-echo-poc:latest

    cd $GIT_PATH_SIGEVENTS/poc/spinnaker
    kubectl apply -f spin-echo-deploy.yaml

}

function createTriggerToSubscribeSpinnakerEvent() {
kubectl create -f - <<EOF
apiVersion: eventing.knative.dev/v1
kind: Trigger
metadata:
  name: cd-artifact-published-to-spinnaker-poc
spec:
  broker: events-broker
  filter:
    attributes:
      type: cd.artifact.published.v1
  subscriber:
    uri: http://spin-echo.spinnaker:8089/cdevent/consume
EOF
}

function createApplicationAndPipeline() {

    sudo netstat -tulpn | grep 8084 &&
        echo "Spinnaker API gateway is running, proceeding with pipeline creation." ||
        echo "Spinnaker API gateway is NOT running, please run 'hal deploy connect' and 'source ./installAndConfigSpinnaker.sh && createApplicationAndPipeline'"

    ##** Run hal deploy connect - from the VM before pipeline creation..
    spin application save --application-name cdevents-poc --owner-email someone@example.com --cloud-providers "kubernetes"
    cd $GIT_PATH_SIGEVENTS/poc/spinnaker
    spin pipeline save -f deploy-spinnaker-poc.json
    echo "Spinnaker Application and Pipeline created successfully"
}

########
## Main
#######
installHelm
installHalyard
installSpinCLI

installMinioService
configureK8SAccountWithSpinnaker
installSpinnaker
createTriggerToSubscribeSpinnakerEvent
createApplicationAndPipeline
exit 0
