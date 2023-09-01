#!/bin/sh

kubectl get pods -n cdevents | grep 'build-artifact-' | awk '{print $1}' | xargs kubectl delete pod -n cdevents
docker exec -it cde-control-plane crictl rmi --prune
docker exec -it cde-worker crictl rmi --prune
docker exec -it cde-worker2 crictl rmi --prune
docker system prune --all --force --volumes
