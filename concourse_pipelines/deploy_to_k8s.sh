#!/bin/sh -e

echo "$KEY_JSON" > /tmp/service_account_key.json
ls -lh /tmp/service_account_key.json

GARBANZO_TAG=`cat redesigned-garbanzo/.git/short_ref`
export GARBANZO_TAG

echo "deploying with ${GARBANZO_TAG}"

gcloud auth activate-service-account --key-file=/tmp/service_account_key.json
gcloud container clusters get-credentials "$CLUSTER" --zone "$ZONE" --project "$PROJECT"

kubectl -n concourse get secret gpg-key -o jsonpath='{.data.secretKey}' | base64 -d > /tmp/secretKey.asc

echo "Importing secret key..."
gpg --import /tmp/secretKey.asc

cd redesigned-garbanzo
echo

helmsman --apply -f helmsman_dsf.yml
