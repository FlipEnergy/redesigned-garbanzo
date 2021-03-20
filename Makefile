deploy:
	docker run --rm -it \
	-v $$(pwd):/garbanzo \
	-v ~/.kube/config:/root/.kube/config \
	-v ~/.gnupg:/root/.gnupg \
	-w /garbanzo \
	-e GARBANZO_TAG=$$GARBANZO_TAG \
	praqma/helmsman:v3.6.6 \
	helmsman $(options) --apply -f helmsman_dsf.yml

up:
	docker-compose up --build --remove-orphans -d

stop:
	docker-compose stop

down:
	docker-compose down

shell:
	docker exec -it garbanzo /bin/sh

psql:
	# POSTGRESQL_POSTGRES_PASSWORD in docker-compose is the password
	docker exec -it postgresql psql -U postgres

logs:
	docker-compose logs -f

# a utility image that runs in concourse for deployments to GKE
gcloud_helmsman:
	docker build -t gcr.io/gorgias-callenge/gcloud_helmsman -f concourse_pipelines/gcloud_helmsman_Dockerfile .
	docker push gcr.io/gorgias-callenge/gcloud_helmsman

pipeline:
	fly -t garbanzo login -k -c http://garbanzo-concourse.duckdns.org/
	sops -d concourse_pipelines/secrets.enc.yml > concourse_pipelines/secrets.dec.yml
	-fly -t garbanzo set-pipeline -n -p build-and-deploy -c concourse_pipelines/build_and_deploy.yml -l concourse_pipelines/secrets.dec.yml
	rm -vf concourse_pipelines/secrets.dec.yml
