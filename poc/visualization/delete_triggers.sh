#!/bin/sh

kubectl delete trigger cdevents-visualiser-receiver
kubectl delete trigger cd-artifact-packaged-to-keptn-in

echo "Current triggers in use:"
kubectl get triggers
