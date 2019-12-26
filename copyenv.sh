#!/bin/bash

SERVICE=$1
if [ -z "$SERVICE" ]; then
    echo >&2 "ERROR: service name expected"
    exit 1
fi

DEST=$2
if [ -z "$DEST" ]; then
    DEST=/workspace/.env
fi

# FIXME: platform, region should be options
gcloud run configurations describe $SERVICE \
    --format json --platform managed --region us-east1 |
    jq -r '.spec.template.spec.containers[0].env[] | "\(.name)=\(.value)"' \
        >$DEST
