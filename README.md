# redesigned-garbanzo
A flask to do list app backed by PostgreSQL

# Links to Live Project

[kube-ops-view](http://garbanzo-kube.duckdns.org/#reload=600;scale=3)

[concourse CICD pipeline](http://garbanzo-concourse.duckdns.org/teams/main/pipelines/build-and-deploy)

[To Do List Flask App](http://garbanzo-app.duckdns.org)

## Dependencies

### google SDK
You need gcloud cli to auth against the cluster

### kubectl
We're working with a k8s cluster so you might want to install this too.

### Docker and Docker-compose
To avoid downloading tools, I just use docker images of them. Easier to upgrade and maintain. Local dev will also be using docker and docker-compose. We'll be runninng [Helmsman](https://github.com/Praqma/helmsman) thru docker for deployments.

### Helm3
Even though Helm is not used directly, it's necessary to use the Helm secrets plugin.
How to install helm3: https://helm.sh/docs/intro/install/

### [Helm secrets plugin](https://github.com/jkroepke/helm-secrets)
I want to avoid spinning up infrastructure like Hashicorp Vault for secret management and manually putting in kubernetes secrets. This allows us to encrypt yaml easily so we can commit them into the git repo. It uses [sops](https://github.com/mozilla/sops) under the hood which uses GPG keys to encrypt yaml files.
```
# install using
helm plugin install https://github.com/jkroepke/helm-secrets
```

### GPG
Hopefully this is already installed. We'll need it for encrypting/decrypting the secret yamls. You can probably install it for your system fairly easily from a package manager.

## Optional

### make
I like to keep a makefile in a project for easy aliases that are maintained and scoped within the project. This allows for a single, easy make command for deployment for example. If your computer doesn't have make installed already and don't want to bother installing make, feel free to just run the commands in the Makefile directly. I'll also give command snippits in docs to show you how to deploy.

### fly
fly is the cli tool to interact with concourse such as setting up a pipeline. If you want to install it, you can download it from the homepage of the concourse instance (see **Links to Live Project** for link)

## Other Tools

### [Helmsman](https://github.com/Praqma/helmsman)
Helmsman lets me specify multiple helm charts and their override values in a nice yaml format such that I don't need to write a script to call helm multiple times. It has great features like prioritization, auto secrets decrypting, hooks, etc. Best of all, the yaml you write is a desired state file (see [helmsman_dsf.yml](helmsman_dsf.yml)), meaning if the k8s cluster is already running stuff in the state you specified, it's a no-op, meaning running helmsman is completely idempotent. Great for CI.
I'm running it thru docker.

### [Concourse](https://concourse-ci.org/)
I love this CI system mostly due to the UI. It's the main CI system at my current work and also my CI/automation system of choice for my Homelab. 

Since I will be using concourse for CICD, it needs to also have the GPG key to decode the helm secrets.

So a manual step of adding a kubernetes secret is necessary and I have done this already but here's the command for reference:

```
# assuming concourse namespace is created
kubectl -n concourse create secret generic gpg-key --from-file=secretKey=<path to secret key>
```

For this project, the pipeline consists of 3 jobs. The first one is triggered automatically on any repo commit to the main branch. It simply runs pycodestyle and lints the python files. The second job will build the docker image then push it to google image repository. The final job then takes that image and deploys it to k8s. In bigger project, there could be other jobs like different sized tests, maybe packaging and pushing of helm charts, etc and many of these jobs could be run in parallel until finally we deploy the app.

Some optimizations here would be to only lint and build image on src code change and only deploy on either helm chart update or new image. Another option is rather than treating images as the artifact, a helm package could be produced which would incorporate the correct image tag. That would require the automation to be a little more sophisticated and edit yaml so I didn't do it for this project.

### [Gunicorn](https://docs.gunicorn.org/en/stable/index.html)
When running Flask apps in production, one would want to it as a WSGI process in production. In k8s, I opted to run gunicorn will run 2 instances Flask workers because 1) the nodes appear to have 2 cores/CPUs, and 2) we want to run at least 2 since one Flask worker/instance will be occupied with health check calls part of the time. I did not opt to run it as a gevent because while gevent is good for asynchronous work that block often, serving synchronous requests, even if it does get blocked by a database query for example, we would want that request to return ASAP with minimal latency. Gevent is a co-operative threading (coroutine) module, and unless threads, co-routines are pseudo-threads that will only give CPU time to other threads upon yielding, meaning a request in thread A could still be waiting for it's turn to run because thread B hasn't yielded, resulting in a delayed response.

## Directories in this Repo

### concourse_pipelines
Concourse Pipeline Yaml definition for CICD pipeline as well as scripts the jobs run. It also has a Dockerfile for the image that the deploy-to-k8s job runs which has the gcloud and helmsman tools.

### helm_charts
Helm chart for deploying this flask app as well as override files for the other charts used


### src
Python source code for the flask app

## Initial Local Setup
1. Install the tools from the **Dependencies** section above
2. make sure your current working directory is at the root of this repo. All commands in this doc assume you're at the root of the repo
3. authenticate with gcloud using `gcloud auth login` then connect to the k8s cluster with `gcloud container clusters get-credentials cluster-1 --zone us-central1-c --project gorgias-callenge`
4. Get the GPG key from the kubernetes secret with `kubectl -n concourse get secret gpg-key -o jsonpath='{.data.secretKey}' | base64 -d > /tmp/secretKey.asc`
5. Import the GPG key to your keychain using `gpg --import /tmp/secretKey.asc`
6. Test that you can dcrypt the secret files with `helm secrets view helm_charts/garbanzo/secrets.garbanzo-creds.yaml`. You should see yaml printed to stdout.

## Local Development
I prefer development in a containerized environment. Docker-compose makes spinning up the app and dependencies fairly easy and we can ensure we're running the same databse image to keep things aligned. By default, the app is running flask in debug mode and you can hit the site at localhost:5000. You can comment out the line for `command:` to run it in WSGI gunicorn to be more "prod-like". If you do it this way, it'll be on port 8000 instead.

Spin up a local environment with 
`make up`
or
`docker-compose up --build -d`

Stop it with
`make stop`
or
`docker-compose stop`

Tear down with
`docker-compose down`

Alternatively, thanks to pipenv, you can also just develop locally without docker if you prefer. You will need to ensure you have python3.8 and pipenv installed. Then `cd` to the src directory and run a `pipenv sync` to install the dependent packages to the virtualenv. Once the virtualenv is setup, you can make a shell in it with `pipenv shell` to source it. Make sure set the proper environment variables to pass the postgres creds to flask and run the migrations against the postgres DB using. In the pipenv shell, you can migrate by running `flask db upgrade`.

## Deploy to K8s
I chose to make a helm chart for the app to deploy it to k8s because it was the simplest option in my mind. Currently, the chart lives in the repo and use it locally rather than packaged. Currently, the artifact that we wish to deploy to k8s is the docker image of the app but ideally, I would make it so the helm chart package be the actual artifact we deploy because it would pin not only the image version in it, but also the chart's version too.

The chart simply spins up a deployment with 3 pods of our flask app running in gunicorn. It will first run a init container to run the DB migrations and since the commands are idempotent, the fact that we have 3 pods is no issue. Alternatively, we could run it as a kubernetes job. In a real prod scenario, these migrations need to be forward compatible and non-table-locking so running the migrations won't break the existing app version serving traffic.

### Deploy from local
Assuming you have your google auth and kube config set up, deploying the app at the latest upstream main commit and postgres (plus the kube-ops-view and concourse) is as simple as running:
```
GARBANZO_TAG=$(git rev-parse --short origin/main) make deploy
```
or without make, using docker directly
```
GARBANZO_TAG=$(git rev-parse --short origin/main) docker run --rm -it \
	-v $(pwd):/garbanzo \
	-v ~/.kube/config:/root/.kube/config \
	-v ~/.gnupg:/root/.gnupg \
	-w /garbanzo \
	-e GARBANZO_TAG=$GARBANZO_TAG \
	praqma/helmsman:v3.6.6 \
	helmsman --apply -f helmsman_dsf.yml
```

It spins up a docker container running Helmsman which will take the [helmsman_dsf.yml](helmsman_dsf.yml) as the desired state and update the k8s cluster to match the state. In this case, it'll spin up postgres (and kube-ops-view) first since it's a dependency, wait until it's ready then it will deploy the app.

Note: if you get errors about gcloud, then you just need to run a kubectl command to re-authenticate. Something like `kubectl get pods` will do.

### Deploy using concourse
If you wish to deploy the latest version of the app + helm chart, simply go to this [link](http://garbanzo-concourse.duckdns.org/teams/main/pipelines/build-and-deploy/jobs/deploy-to-k8s), login with creds found on line `localUsers: <username>:<password>` in the output of `helm secrets view helm_charts/concourse/secrets.concourse-creds.yaml | grep localUsers` and hit the `+` button on the top right to trigger another run (which would likely be a no-op since it's already the latest deployed).

### Deploying from scratch
Let's say we want to nuke whole project and redeploy it. The only thing that we cannot really delete because I manually added was the GPG key secret, so I'm gonna avoid deleting namespaces, or more specifically, the concourse secret gpg-key. Aside from that, we can go thru the steps below to delete everything running.

1. We can uninstall all the helm charts by change the `enabled` flag in `helmsman_dsf.yml` to `false`, which means helm uninstall will be run on each of them.
2. once step 1 is done, we can run the same deploy command from local: `make deploy`
3. delete the PVCs with
```
kubectl -n postgresql delete pvc/data-postgresql-postgresql-primary-0 pvc/data-postgresql-read-0
kubectl -n concourse delete pvc/data-concourse-postgresql-0
```
4. at this point the only thing left is the secret gpg-key we want to keep, so let's bring everything back up
5. to setup everything again with a clean slate, revert your change to `helmsman_dsf.yml` so everything is enabled and just run `GARBANZO_TAG=$(git rev-parse --short origin/main) make deploy`
6. Due to the database reset, the concourse pipeline is gone, so if you want that back, run `make pipeline` and log in with the creds from `helm secrets view helm_charts/concourse/secrets.concourse-creds.yaml | grep localUsers`
7. You should see the [pipeline](http://garbanzo-concourse.duckdns.org/teams/main/pipelines/build-and-deploy) now there but in a paused state. Feel free to click the triangle play button on the top right to unpause it after logging in.

## Misc Info and Thoughts Dump

### pipenv
- pipenv has dependency resolution and locking of these dependency tree versions which I think is highly desirable
- works well in a docker image to ensure package and python versions are synced from dev to prod

### garbanzo Dockerfile
- went with the official python image as base with a version that supports the packages I need
- create a separate user to not run as root
- separate layer for Pipfile and Pipfile.lock so it can be cached for local development
- Currently, one dockerfile is used for dev and prod, mostly because I didn't install any dev only packages. An option if we do need extra packages for dev is to have separate dev dockerfile and prod dockerfiles. Dev docker files can run pipenv with dev packages installed and avoid adding the src code to the image since we mount it using docker-compose anyways. Prod image then could have a single layer which copy in the source code then builds the pipenv without the dev packages. These two images could be based off a common base image that just create the user.

### postgres
- deployed via helm using a bitnami chart which already support replication
- I configured it to use async replication
- soft anti-affinity between the two postgres pods to try to keep them on separate k8s nodes
- Overall just a really nice and well implemented chart that I use for my Homelab. Why reinvent the wheel?

### concourse
- pipeline to build image on new commits to repo then deploys if image builds successfully
- uses a Google service account to push/pull images and deploy to k8s. Has limited permissions
- I had to make a new image that included both helmsman and google SDK for the service account to be able to deploy
- it also uses postgres as a database so it has it's own instance of postgres and creds. I wanted to isolate it so we can tear it down independent of the app

### Kube-ops-view
- nice visualization of pods on the nodes that I like to use
- If you're unfamiliar with this tool, I recommend you watch it when deploying pods. The animations are cool
- I slightly modified a deprecated helm chart for this project so the chart is in the repo at helm_charts/kube-ops-view

### Duck DNS
- a free and super quick setup DNS service that allows me to use a sub domain of www.duckdns.org

### HTTPS
- Yes, I would've setup Let's Encrypt for HTTPS in a more permanent project

### There's a typo in the GKE project ID
- yeah... typed too fast and missed the h. Since I can't change it and this is temporary, I'll just keep it like that.

### Why is the repo named redesigned-garbanzo?
- because that's the auto generated repo name github suggested

### Some ways to improve the app off the top of my head
- better error handling in case of database or connection to database issues
- pagination of list rathern than returning it all every time
- obviously better designed frontend
- stop using ORM? This one is debatable but in some situations ORM could cause performance issues
- treat packaged helm charts with specific image versions as the artifact to deploy rather than using the docker image and a local chart as it is currently
- of course other features like deleting or crossing off something from the list
- setup monitoring and alerting. Google console's features are a good start but we probably want something like influxdb + grafana or some proprietary solution like Datadog

### You can feel free to checkout my homelab project
- [website](https://pleasenoddos.com)
- [Repo for configuration management of hardware](https://github.com/FlipEnergy/ansible-playground)
- [Repo for managing the helm charts and apps I deploy into my k8s](https://github.com/FlipEnergy/k8s-homelab)
