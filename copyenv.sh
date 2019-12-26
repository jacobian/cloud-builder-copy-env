#!/bin/bash

SERVICE=
DEST=/workspace/.env
REGION=us-central1
PLATFORM=managed

OPTS=$(getopt -o s:d:r:p: --long service:,dest:,region:,platform: -- "$@")
if [ $? != 0 ]; then
    echo "Failed parsing options." >&2
    exit 1
fi
eval set -- "$OPTS"

while true; do
    case "$1" in
    -s | --service)
        SERVICE=$2
        shift 2
        ;;
    -d | --dest)
        DEST=$2
        shift 2
        ;;
    -r | --region)
        REGION=$2
        shift 2
        ;;
    -p | --platform)
        PLATFORM=$2
        shift 2
        ;;
    --)
        shift
        ;;
    *)
        break
        ;;
    esac
done

if [ -z "$SERVICE" ]; then
    echo >&2 "ERROR: -s/--service required"
    exit 1
fi

echo "copyenv service=$SERVICE dest=$DEST platform=$PLATFORM region=$REGION"

gcloud run configurations describe $SERVICE \
    --format json --platform $PLATFORM --region $REGION |
    jq -r '.spec.template.spec.containers[0].env[] | "\(.name)=\(.value)"' \
        >$DEST
