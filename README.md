# redesigned-garbanzo
A flask to do list app backed by PostgreSQL

# Links to Live Project

[kube-ops-view](http://garbanzo-kube.duckdns.org/#reload=600;scale=3)

[concourse](http://garbanzo-concourse.duckdns.org)

[To Do List Flask App](http://garbanzo-app.duckdns.org)

## Dependencies

### Docker and Docker-compose
To avoid downloading tools, I just use docker images of them. Easier to upgrade and maintain. Local dev will also be using docker and docker-compose. We'll be runninng [Helmsman](https://github.com/Praqma/helmsman) thru docker for deployments.

### Helm3
Even though Helm is used directly, it's necessary to use the Helm secrets plugin.
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

### [Gunicorn](https://docs.gunicorn.org/en/stable/index.html)
When running Flask apps in production, one would want to it as a WSGI process in production. In k8s, I opted to run gunicorn will run 2 instances Flask workers because 1) the nodes appear to have 2 cores/CPUs, and 2) we want to run at least 2 since one Flask worker/instance will be occupied with health check calls part of the time. I did not opt to run it as a gevent because while gevent is good for asynchronous work that block often, serving synchronous requests, even if it does get blocked by a database query for example, we would want that request to return ASAP with minimal latency. Gevent is a co-operative threading (coroutine) module, and unless threads, co-routines are pseudo-threads that will only give CPU time to other threads upon yielding, meaning a request in thread A could still be waiting for it's turn to run because thread B hasn't yielded, resulting in a delayed response.

## Directories

### concourse_pipelines
Concourse Pipeline Yaml definition for CICD pipeline

### helm_charts
Helm chart for deploying this flask app as well as override files for the other charts used


### src
Python source code for the flask app

## Initial Local Setup
1. Install the tools from the **Dependencies** section
2. Get the GPG key from me.
3. Import the GPG key to your keychain using `gpg --import <path/to/key>`
4. Test that you can access the secrets with `helm secrets view helm_charts/postgresql/secrets.postgres-creds.yaml`. You should see yaml printed to stdout.

## Local Development
I prefer development in a containerized environment. Docker-compose makes spinning up the app and dependencies fairly easy and we can ensure we're running the same databse image to keep things aligned. By default, the app is running flask in debug mode and you can hit the site at localhost:5000. You can comment out the line for `command:` to run it in WSGI gunicorn to be more "prod-like". If you do it this way, it'll be on port 8000 instead. Spin up a local environment with 
`make up`
or
`docker-compose up --build -d`

Then stop it with
`make stop`
or
`docker-compose stop`

Tear down with
`docker-compose down`

## Deploy to K8s

### Deploy from local
Assuming you have kubectl set up, deploying the app and dependencies (plus the other tools I added) is as simple as running
`make deploy`

It spins up a docker container running Helmsman which will take the [helmsman_dsf.yml](helmsman_dsf.yml) as the desired state and update the k8s cluster to match the state. In this case, it'll spin up postgres (and kube-ops-view) first since it's a dependency, wait until it's ready then it will deploy the app.

### Deploy using concourse
If you wish to deploy the latest version of the app + helm chart, simply go to this [link](TODO), login with creds found on line `localUsers: <username>:<password>` and hit the `+` button on the top right.

## Info Dump

### postgres
- deployed via helm using a bitnami chart which already support replication
- I configured it to use async replication
- soft antiaffinity between the two postgres pods to try to keep them on separate k8s nodes
- Overall just a really nice and well implemented chart that I use for my Homelab. Why reinvent the wheel?

### concourse
- pipeline to build image on new commits to repo then deploys if image builds successfully
- uses a Google service account to authenticate, but account has editor permissions. In a real scenario, I'd lock it down to just the necessary permissions

### Kube-ops-view
- nice visualization of pods on the nodes that I like to use
- You can hit it by clicking the link in the **Links to Live Project** section

### Duck DNS
- a free and super quick setup DNS service that allows me to use a sub domain of duckdns.org

### HTTPS
- Yes, I would've setup Let's Encrypt for HTTPS in a real project
