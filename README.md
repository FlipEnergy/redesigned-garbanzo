# redesigned-garbanzo
A flask to do list app backed by PostgreSQL


## Dependencies

### Docker
To avoid downloading tools, I just use docker images of them. Easier to upgrade and maintain. We'll be runninng [Helmsman](https://github.com/Praqma/helmsman) thru docker for deployments.

### Helm3
Even though Helm is not needed directly, it's necessary to use the Helm secrets plugin.
How to install helm3: https://helm.sh/docs/intro/install/


### [Helm secrets plugin](https://github.com/jkroepke/helm-secrets)
I want to avoid spinning up infrastructure like Hashicorp Vault for secret management and manually putting in kubernetes secrets. This allows us to encrypt yaml easily so we can commit them into the git repo. If you're French and are expecting a key, you will get it to unlock the secrets.
```
# install using
helm plugin install https://github.com/jkroepke/helm-secrets
```


## Optional but recommended Dependencies
Make: I like to keep a makefile in a project for easy aliases that are maintained and scoped within the project. A single easy make command for deployment for example. I your computer doesn't have make installed already and don't want to bother installing make, feel free to just run the commands in the Makefile directly. I'll also give command snippits in docs to show you how to deploy.


## Initial setup
1. Install the tools from the **Dependencies** section
2. Get the GPG key from me.
3. Import the GPG key to your keychain using `gpg --import <path/to/key>`
4. Test that you can access the secrets with `helm secrets view helm_charts/postgresql/secrets.postgres-creds.yaml`. You should see yaml printed to stdout.


## Info Dump

### postgres
- deployed via helm using a bitnami chart which already support replication
- I configured it to use async replication
- soft antiaffinity between the two postgres pods to try to keep them on separate k8s nodes
