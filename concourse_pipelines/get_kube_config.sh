#!/usr/bin/env bash

set -e

echo "$KEY_JSON" > key.json

ls -lh key.json

gcloud auth activate-service-account --key-file=key.json
gcloud container clusters get-credentials "$CLUSTER" --zone "$ZONE" --project "$PROJECT"

cp -v /root/.kube/config redesigned-garbanzo/kube_config

# install kubectl
gcloud components install kubectl --quiet

kubectl -n concourse get secret gpg-key -o jsonpath='{.data.secretKey}' | base64 --decode > redesigned-garbanzo/secretKey.asc
