# Configuration

This repository contains the configuration for the Observatorium instances that the team runs.

[![Build Status](https://circleci.com/gh/observatorium/configuration.svg?style=svg)](https://circleci.com/gh/observatorium/configuration)

# Observatorium Operator

See [Docs](https://github.com/observatorium/docs/) repo and [API](https://github.com/observatorium/observatorium/) repo for more details on Observatorium.

In order to ease the installation of Observatorium, an operator is available.

The operator is based on [locutus](https://github.com/brancz/locutus).



## How to deploy

### Prerequisites

#### S3 storage endpoint and secret.

For testing purposes you may use [minio](https://github.com/minio/minio) as describe below.

It will create `minio` and `observatorium` namespaces, a minio environment in `minio` namespace and a secret with needed credentials in `observatorium` namespace.

Note that you need a default Storage Class available as a PVC is needed for the minio environment.

```
kubectl create namespace minio
kubectl create namespace observatorium
kubectl create -f https://raw.githubusercontent.com/observatorium/configuration/master/environments/dev/manifests/minio-secret.yaml
kubectl create -f https://raw.githubusercontent.com/observatorium/configuration/master/environments/dev/manifests/minio-pvc.yaml
kubectl create -f https://raw.githubusercontent.com/observatorium/configuration/master/environments/dev/manifests/minio-deployment.yaml
kubectl create -f https://raw.githubusercontent.com/observatorium/configuration/master/environments/dev/manifests/minio-service.yaml
```

#### RBAC configuration

```
kubectl create -f https://raw.githubusercontent.com/observatorium/configuration/master/deploy/cluster_role.yaml
kubectl create -f https://raw.githubusercontent.com/observatorium/configuration/master/deploy/cluster_role_binding.yaml
```


#### Install CRDs
```
kubectl -n observatorium create -f https://raw.githubusercontent.com/observatorium/configuration/master/deploy/crds/obs-api.observatorium.io_observatoria.yaml
kubectl apply -f https://raw.githubusercontent.com/coreos/kube-prometheus/master/manifests/setup/prometheus-operator-0servicemonitorCustomResourceDefinition.yaml
kubectl apply -f https://raw.githubusercontent.com/coreos/kube-prometheus/master/manifests/setup/prometheus-operator-0prometheusruleCustomResourceDefinition.yaml
```

#### Install Operator
```
kubectl create -f https://raw.githubusercontent.com/observatorium/configuration/master/deploy/operator.yaml
```

### Deploy an example CR
```
kubectl -n observatorium create -f https://raw.githubusercontent.com/observatorium/configuration/master/example/obs-cr-example.yaml
```
