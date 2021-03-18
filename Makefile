deploy:
	docker run --rm -it \
	-v $$(pwd):/garbanzo \
	-v ~/.kube/config:/root/.kube/config \
	-v ~/.gnupg:/root/.gnupg \
	-w /garbanzo \
	-e GARBANZO_TAG=$$GARBANZO_TAG \
	praqma/helmsman:v3.6.6 \
	helmsman $(options) -show-diff --apply -f helmsman_dsf.yml

up:
	docker-compose up --build --remove-orphans -d

stop:
	docker-compose stop

shell:
	docker exec -it garbanzo /bin/sh

logs:
	docker-compose logs -f

gcloud_helmsman:
	docker build -t gcr.io/gorgias-callenge/gcloud_helmsman .
	docker push gcr.io/gorgias-callenge/gcloud_helmsman

pipeline:
	fly -t garbanzo login -k -c http://garbanzo-concourse.duckdns.org/
	sops -d concourse_pipelines/secrets.enc.yml > concourse_pipelines/secrets.dec.yml
	-fly -t garbanzo set-pipeline -n -p build-and-deploy -c concourse_pipelines/build_and_deploy.yml -l concourse_pipelines/secrets.dec.yml
	rm -vf concourse_pipelines/secrets.dec.yml
