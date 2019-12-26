FROM gcr.io/cloud-builders/gcloud-slim

RUN apt-get -y update && \
    apt-get -y install jq && \
    rm -rf /var/lib/apt/lists/*

COPY copyenv.sh /buildstep/copyenv.sh
ENTRYPOINT ["/buildstep/copyenv.sh"]