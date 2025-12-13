#!/usr/bin/env bash
# Генерация kubeconfig для пользователя.

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <username>"
  exit 1
fi

USER="$1"
WORKDIR="./certs/${USER}"

if [[ ! -f "${WORKDIR}/${USER}.crt" ]]; then
  echo "User cert not found: ${WORKDIR}/${USER}.crt. Run 40-create-user.sh first."
  exit 1
fi

# Получаем параметры текущего кластера из kubectl
CLUSTER_NAME=$(kubectl config view -o jsonpath='{.clusters[0].name}')
CLUSTER_SERVER=$(kubectl config view -o jsonpath='{.clusters[0].cluster.server}')
CLUSTER_CA=$(mktemp)
kubectl config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 -d > "$CLUSTER_CA"

KCONF="${WORKDIR}/${USER}-kubeconfig"

kubectl config --kubeconfig="$KCONF" set-cluster "$CLUSTER_NAME"   --server="$CLUSTER_SERVER"   --certificate-authority="$CLUSTER_CA"   --embed-certs=true

kubectl config --kubeconfig="$KCONF" set-credentials "$USER"   --client-certificate="${WORKDIR}/${USER}.crt"   --client-key="${WORKDIR}/${USER}.key"   --embed-certs=true

kubectl config --kubeconfig="$KCONF" set-context "${USER}@${CLUSTER_NAME}"   --cluster="$CLUSTER_NAME"   --user="$USER"

kubectl config --kubeconfig="$KCONF" use-context "${USER}@${CLUSTER_NAME}"

echo "Kubeconfig для пользователя сохранён: ${KCONF}"