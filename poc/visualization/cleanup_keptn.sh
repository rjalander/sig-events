#!/bin/sh

KEPTN_PROJECT=${KEPTN_PROJECT:-cde}
KEPTN_SERVICE=${KEPTN_SERVICE:-poc}
keptn delete project "$KEPTN_PROJECT" > /dev/null || true
BASE_DIR=/home/ubuntu/sig-events/poc
keptn create project "$KEPTN_PROJECT" --shipyard="$BASE_DIR/resources/shipyard.yaml"
keptn create service "$KEPTN_SERVICE" --project="$KEPTN_PROJECT"

echo "Login keptn Dashboard with User 'keptn' & Password '$(kubectl get secret -n keptn bridge-credentials -o jsonpath="{.data.BASIC_AUTH_PASSWORD}" | base64 --decode)'"
