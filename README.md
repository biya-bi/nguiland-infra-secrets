# Introduction

This is a Secret as Code project. Its purpose is to manage secrets in a simple but secure way. By so doing, secrets can be kept encrypted in the Git repository and their life cycles managed via pull requests. With this approach, we can take advantage of GitOps tools such as [Flux](https://fluxcd.io/flux/) which will decrypt the secrets and apply the decrypted secrets to a Kubernetes cluster for example.

# Secret Creation
Artifactory secrets can be created using a command similar to the below:
```
scripts/create-artifactory-secret.sh <env> <system_name>
```

Postgres secrets can be created using a command similar to the below:
```
scripts/create-postgres-secret.sh <env>
```

Keycloak secrets can be created using a command similar to the below:
```
scripts/create-keycloak-secret.sh <env>
```

Maven secrets can be created using a command similar to the below:
```
scripts/create-maven-settings-secret.sh <env>
```

Docker secrets can be created using a command similar to the below:
```
scripts/create-docker-config-secret.sh <env>
```