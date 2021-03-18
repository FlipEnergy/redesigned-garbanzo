#!/bin/sh -e

GARBANZO_TAG=`cat redesigned-garbanzo/.git/short_ref`
export GARBANZO_TAG

echo "deploying with ${GARBANZO_TAG}"

echo "Importing secret key..."
gpg --import redesigned-garbanzo/secretKey.asc

echo "Setting up kube config..."
mkdir -p ~/.kube
mv -vf redesigned-garbanzo/kube_config ~/.kube/config
chmod 600 ~/.kube/config

cd redesigned-garbanzo
echo

helmsman --apply -f helmsman_dsf.yml
