# Introduction

This is a Secret as Code project. Its purpose is to manage secrets in a simple but secure way. By so doing, secrets can be kept encrypted in the Git repository and their life cycles managed via pull requests. With this approach, we can take advantage of GitOps tools such as [Flux](https://fluxcd.io/flux/) which will decrypt the secrets and apply the decrypted secrets to a Kubernetes cluster for example.
