#!/bin/sh

kubectl delete -f ~/visualization_python_poc/python-poc/python-reciever/cdeventreciever.yaml
kubectl delete -f ~/visualization_python_poc/python-poc/arango/storage.yaml

kubectl wait -n default --for=condition=ready pods --all --timeout=120s

kubectl apply -f ~/visualization_python_poc/python-poc/python-reciever/cdeventreciever.yaml
kubectl apply -f ~/visualization_python_poc/python-poc/arango/storage.yaml
