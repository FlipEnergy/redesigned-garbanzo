# redesigned-garbanzo
A flask to do list app backed by PostgreSQL

# Links to Live Project

[kube-ops-view](http://garbanzo-kube.duckdns.org/#reload=600;scale=3)

[concourse CICD pipeline](http://garbanzo-concourse.duckdns.org/teams/main/pipelines/build-and-deploy)

[To Do List Flask App](http://garbanzo-app.duckdns.org)

## Dependencies

### Docker and Docker-compose
To avoid downloading tools, I just use docker images of them. Easier to upgrade and maintain. Local dev will also be using docker and docker-compose. We'll be runninng [Helmsman](https://github.com/Praqma/helmsman) thru docker for deployments.

### Helm3
Even though Helm is not used directly, it's necessary to use the Helm secrets plugin.
How to install helm3: https://helm.sh/docs/intro/install/

### [Helm secrets plugin](https://github.com/jkroepke/helm-secrets)
I want to avoid spinning up infrastructure like Hashicorp Vault for secret management and manually putting in kubernetes secrets. This allows us to encrypt yaml easily so we can commit them into the git repo. If you're French and are expecting a key, you may get it to unlock the secrets.
```
# install using
helm plugin install https://github.com/jkroepke/helm-secrets
```

## Optional

### make
I like to keep a makefile in a project for easy aliases that are maintained and scoped within the project. A single easy make command for deployment for example. I your computer doesn't have make installed already and don't want to bother installing make, feel free to just run the commands in the Makefile directly. I'll also give command snippits in docs to show you how to deploy.

### fly
fly is the cli tool to interact with concourse such as setting up a pipeline. If you want to install it, you can download it from the homepage of the concourse instance (see **Links to Live Project** for link)

## Other Tools

### [Helmsman](https://github.com/Praqma/helmsman)
Helmsman lets me specify multiple helm charts and their override values in a nice yaml format such that I don't need to write a script to call helm multiple times. It has great features like prioritization, auto secrets decrypting, hooks, etc. Best of all, the yaml you write is a desired state file, meaning if the k8s cluster is already running stuff in the state you specified, it's a no-op, meaning running helmsman is completely idempotent. Great for CI.
I'm running it thru docker.

### [Concourse](http://garbanzo-concourse.duckdns.org/teams/main/pipelines/build-and-deploy)
I love this CI system mostly due to the UI. It's the main CI system at my current work and also my CI/automation system of choice for my Homelab. For this project, it will run a simple CICD system of building the image then using a helm chart to deploy it to k8s.

Since I will be using concourse for CICD, it needs to also have the GPG key to decode the helm secrets.

So a manual step of adding a kubernetes secret is necessary and I have done this already but here's the command for reference:

```
# assuming concourse namespace is created
kubectl -n concourse create secret generic gpg-key --from-file=secretKey=<path to secret key>
```

The pipeline consists of 2 jobs. The first one is triggered automatically on any repo commit to the main branch. It will build the docker image then push it to google image repository. The second job then takes that image and deploys it to k8s.

Some optimizations here would be to only build image on src code change and only deploy on either helm chart update or new image. Another option is rather than treating images as the artifact, a helm package could be produced which would incorporate the correct image tag. That would require the automation to edit yaml so it's a little more work so I didn't do it for this project.

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
2. authenticate with gcloud using `gcloud auth login` then connect to the k8s cluster with `gcloud container clusters get-credentials cluster-1 --zone us-central1-c --project gorgias-callenge`
3. Get the GPG key from the kubernetes secret with `kubectl -n concourse get secret gpg-key -o jsonpath='{.data.secretKey}' | base64 --decode > /tmp/secretKey.asc`
4. Import the GPG key to your keychain using `gpg --import /tmp/secretKey.asc`
5. Test that you can access the secrets with `helm secrets view helm_charts/postgresql/secrets.postgres-creds.yaml`. You should see yaml printed to stdout.

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

Alternatively, thanks to pipenv, you can also just develop locally without docker if you prefer. You will need to ensure you have python3.8 and pipenv installed. Then `cd` to the src directory and run a `pipenv sync` to install the dependent packages to the virtualenv. Once the virtualenv is setup, you can make a shell in it with `pipenv shell` to source it. Make sure set the proper environment variables to pass the postgres creds to flask and run the migrations against the postgres DB using. In the pipenv shell, you can migrate by running `flask db migrate && flask db upgrade`.

## Deploy to K8s
I chose to make a helm chart for the app to deploy it to k8s because it was the simplest option in my mind. Currently, the chart lives in the repo and use it locally rather than packaged. Currently, the artifact that we wish to deploy to k8s is the docker image of the app but ideally, I would make it so the helm chart package be the actual artifact we deploy because it would pin not only the image version in it, but also the chart's version too.

The chart simply spins up a deployment with 3 pods of our flask app running in gunicorn. It will first run a init container to run the DB migrations and since the commands are idempotent, the fact that we have 3 pods is no issue. Alternatively, we could run it as a kubernetes job. In a real prod scenario, these migrations need to be forward compatible and non-table-locking so running the migrations won't break the existing app version serving traffic. 

### Deploy from local
Assuming you have kubectl set up, deploying the app and dependencies (plus the other tools I added) is as simple as running:
```
GARBANZO_TAG=latest make deploy
```
or without make, using docker directly
```
GARBANZO_TAG=latest docker run --rm -it \
	-v $(pwd):/garbanzo \
	-v ~/.kube/config:/root/.kube/config \
	-v ~/.gnupg:/root/.gnupg \
	-w /garbanzo \
	-e GARBANZO_TAG=$GARBANZO_TAG \
	praqma/helmsman:v3.6.6 \
	helmsman -show-diff --apply -f helmsman_dsf.yml
```

It spins up a docker container running Helmsman which will take the [helmsman_dsf.yml](helmsman_dsf.yml) as the desired state and update the k8s cluster to match the state. In this case, it'll spin up postgres (and kube-ops-view) first since it's a dependency, wait until it's ready then it will deploy the app.

### Deploy using concourse
If you wish to deploy the latest version of the app + helm chart, simply go to this [link](http://garbanzo-concourse.duckdns.org/teams/main/pipelines/build-and-deploy/jobs/deploy-to-k8s), login with creds found on line `localUsers: <username>:<password>` in the output of `helm secrets view helm_charts/concourse/secrets.concourse-creds.yaml | grep localUsers` and hit the `+` button on the top right to trigger another run (which would likely be a no-op since it's already the latest deployed).

## Misc Info Dump

### pipenv
- pipenv has dependency resolution and locking of these dependency tree versions which I think is highly desirable
- works well in a docker image to ensure package and python versions are synced from dev to prod

### garbanzo Dockerfile
- went with the official python image as base with a version that supports the packages I need
- create a separate user to not run as root
- separate layer for Pipfile and Pipfile.lock so it can be cached for local development

### postgres
- deployed via helm using a bitnami chart which already support replication
- I configured it to use async replication
- soft anti-affinity between the two postgres pods to try to keep them on separate k8s nodes
- Overall just a really nice and well implemented chart that I use for my Homelab. Why reinvent the wheel?

### concourse
- pipeline to build image on new commits to repo then deploys if image builds successfully
- uses a Google service account to push/pull images and deploy to k8s. Has limited permissions
- I had to make a new image that included both helmsman and google SDK for the service account to be able to deploy
- it also uses postgres as a database so it has it's own database and creds

### Kube-ops-view
- nice visualization of pods on the nodes that I like to use
- You can hit it by clicking the link in the **Links to Live Project** section
- If you're unfamiliar with this tool, I recommend you watch it when deploying pods. The animations are cool

### Duck DNS
- a free and super quick setup DNS service that allows me to use a sub domain of www.duckdns.org

### HTTPS
- Yes, I would've setup Let's Encrypt for HTTPS in a real project

### There's a typo in the project ID
- yeah... typed too fast and missed the h. Since I can't change it and this is temporary, I'll just keep it like that.

### Why is the repo named redesigned-garbanzo?
- because that's the auto generated repo name github suggested
