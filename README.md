# Overview

This provides an example of how using tools like Envoy and Squid can allow for SSL traffic to be terminated, inspected, and modified through an explicit (non-transparent) proxy. 

Envoy is used for mTLS termination, Squid for its SSL-bump functionality.

A custom ICAP server written in Go allows for modification of the requests, and in this example shows that authorization headers can be injected.

![diagram](https://github.com/kiambogo/squid_sandbox/assets/4472397/c12a7832-aac0-478e-bc6e-c78693ccaf83)


# Setup
The following assumes that you have [docker](https://www.docker.com/get-started/) and [minikube](https://minikube.sigs.k8s.io/docs/) installed.

### Compile and build Squid

When running on OSX, you will need to add the generated root CA certificate into the OSX Keychain since `curl` on OSX ignores the `--cacert` option and just defaults to looking in the Keychain.
See https://www.elastic.co/guide/en/elasticsearch/reference/7.17/trb-security-maccurl.html for more info

1. Run `eval $$(minikube docker-env)` to set your current shell to use minikube's local docker registry.
2. Run `make build-squid` to build a Docker image to the local registry.

### Generate root CA cert, client and server certificates.

1. Run `eval $$(minikube docker-env)` to set your current shell to use minikube's local docker registry.
2. Run `make gen-certs` to generate a root CA, server, and client certificates. The server cert is used by Envoy during the mTLS handshake, and the CA cert is used by Squid to issue adhoc certs as part of the SSL bump procedure.
3. 

### Deploy the infrastructure

1. Run `make kube-deploy` to apply the Kubernetes resources which include a deployment with:
  - Envoy container
  - Squid container
  - Squid metrics scraping container
  - ICAP server


### Make proxied HTTPs calls

1. Make a HTTPS request through the proxy. As an example, you can update the icap-server with your GitHub API key and do the following:

```
$ curl -L -x https://localhost:3129 --proxy-cert certs/client.crt --proxy-key certs/client.key --proxy-cacert certs/ca.crt   -H "Accept: application/vnd.github+json"   -H "X-GitHub-Api-Version: 2022-11-28"   https://api.github.com/user -v
```

You'll note that the 'Authorization' header is not being set here in cURL, but instead will be injected by the ICAP server (static key). This shows the ability of the ICAP server to modify the request before it makes it to the internet (`reqmod`).
