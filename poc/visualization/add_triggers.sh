#!/bin/sh

kubectl create -f - <<EOF || true
apiVersion: eventing.knative.dev/v1
kind: Trigger
metadata:
  name: cdevents-visualiser-receiver
  annotations:
    knative-eventing-injection: enabled
spec:
  broker: events-broker
  subscriber:
    uri: http://cdevents-visualiser-service.default:8099/cdevents/visualiser
EOF

kubectl create -f - <<EOF
apiVersion: eventing.knative.dev/v1
kind: Trigger
metadata:
  name: cd-artifact-packaged-to-keptn-in
spec:
  broker: events-broker
  filter:
    attributes:
      type: cd.artifact.packaged.v1
  subscriber:
    uri: http://keptn-cdevents.keptn:8080/events
EOF

echo "Current triggers in use:"
kubectl get triggers
