#!/bin/bash

set -e
set -o pipefail

kind() {
    curl -LO https://storage.googleapis.com/kubernetes-release/release/"$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)"/bin/linux/amd64/kubectl
    curl -Lo kind https://github.com/kubernetes-sigs/kind/releases/download/v0.7.0/kind-linux-amd64
    chmod +x kind kubectl
    ./kind create cluster
}

deploy() {
    ./kubectl apply -f https://raw.githubusercontent.com/coreos/kube-prometheus/master/manifests/setup/prometheus-operator-0servicemonitorCustomResourceDefinition.yaml
    ./kubectl apply -f https://raw.githubusercontent.com/coreos/kube-prometheus/master/manifests/setup/prometheus-operator-0prometheusruleCustomResourceDefinition.yaml
    ./kubectl create ns minio || true
    ./kubectl create ns observatorium || true
    ./kubectl apply -f environments/dev/manifests/
}

wait_for_cr() {
    observatorium_cr_status=""
    target_status="Finished"
    timeout=$true
    interval=0
    intervals=600
    while [ $interval -ne $intervals ]; do
      echo "Waiting for" $1 "currentStatus="$observatorium_cr_status
      observatorium_cr_status=$(./kubectl -n observatorium get observatoria.obs-api.observatorium.io $1 -o=jsonpath='{.status.conditions[*].currentStatus}')
      if [ "$observatorium_cr_status" = "$target_status" ]; then
        echo $1 CR status is now: $observatorium_cr_status
	    timeout=$false
	    break
	  fi
	  sleep 5
	  interval=$((interval+5))
    done

    if [ $timeout ]; then
      echo "Timeout waiting for" $1 "CR status to be " $target_status
      exit 1
    fi
}

deploy_operator() {
    ./kubectl apply -f https://raw.githubusercontent.com/coreos/kube-prometheus/master/manifests/setup/prometheus-operator-0servicemonitorCustomResourceDefinition.yaml
    ./kubectl apply -f https://raw.githubusercontent.com/coreos/kube-prometheus/master/manifests/setup/prometheus-operator-0prometheusruleCustomResourceDefinition.yaml
    ./kubectl create ns minio || true
    ./kubectl create ns observatorium || true
    ./kubectl apply -f environments/dev/manifests/minio-secret.yaml
    ./kubectl apply -f environments/dev/manifests/minio-pvc.yaml
    ./kubectl apply -f environments/dev/manifests/minio-deployment.yaml
    ./kubectl apply -f environments/dev/manifests/minio-service.yaml
    ./kubectl apply -f deploy/crds
    ./kubectl apply -f deploy/
    ./kubectl apply -n observatorium -f example/
    wait_for_cr observatorium-xyz
}

run_test() {
    ./kubectl wait --for=condition=available --timeout=10m -n observatorium deploy/minio || (./kubectl get pods --all-namespaces && exit 1)
    ./kubectl wait --for=condition=available --timeout=10m -n observatorium deploy/observatorium-xyz-thanos-query || (./kubectl get pods --all-namespaces && exit 1)

    ./kubectl apply -f tests/manifests/observatorium-up.yaml

    sleep 5

    # This should wait for ~2min for the job to finish.
    ./kubectl wait --for=condition=complete --timeout=5m -n default job/observatorium-up || (./kubectl get pods --all-namespaces && exit 1)
}

case $1 in
    kind) 
        kind;;

    deploy)
        deploy;;

    test)
        run_test;;

    deploy-operator)
        deploy_operator;;

    *)
        echo "usage: $(basename "$0") { kind | deploy | test | deploy-operator}";;
esac
