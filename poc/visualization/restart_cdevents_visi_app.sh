#!/bin/sh

kubectl delete -f ~/eiffel-vici/cdevents-visi-deployment.yaml
kubectl apply -f ~/eiffel-vici/cdevents-visi-deployment.yaml

kubectl wait -n default --for=condition=ready pods --all --timeout=120s
nohup kubectl -n default port-forward service/cdevents-visi 8080:8080 &
