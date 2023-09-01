#!/bin/sh
nohup kubectl -n knative-eventing port-forward service/broker-ingress 8090:80 &
nohup kubectl -n keptn port-forward service/api-gateway-nginx 8091:80 &
nohup kubectl -n default port-forward service/cloudevents-player-00001-private 8093:80 &
nohup kubectl -n default port-forward service/cdevents-visi 8080:8080 &
nohup kubectl  -n monitoring port-forward  svc/grafana 3000:3000 &

