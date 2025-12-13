#!/usr/bin/env bash
# Создание пользователя через Kubernetes CSR API.

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <username> <group1>[,<group2>,...]"
  exit 1
fi

USER="$1"
IFS=',' read -r -a GROUPS <<< "$2"

WORKDIR="./certs/${USER}"
mkdir -p "$WORKDIR"

# 1) Генерируем ключ и CSR (с множественными O= для групп)
openssl genrsa -out "${WORKDIR}/${USER}.key" 2048

# Формируем subject: /CN=<user>/O=<group1>/O=<group2>/...
SUBJ="/CN=${USER}"
for g in "${GROUPS[@]}"; do
  SUBJ="${SUBJ}/O=${g}"
done

openssl req -new -key "${WORKDIR}/${USER}.key" -out "${WORKDIR}/${USER}.csr" -subj "${SUBJ}"

# 2) Создаём объект CSR в Kubernetes
cat > "${WORKDIR}/${USER}-csr.yaml" <<EOF
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: ${USER}-csr
spec:
  request: $(base64 < "${WORKDIR}/${USER}.csr" | tr -d '\n')
  signerName: kubernetes.io/kube-apiserver-client
  usages:
  - client auth
EOF

kubectl delete csr "${USER}-csr" >/dev/null 2>&1 || true
kubectl apply -f "${WORKDIR}/${USER}-csr.yaml"

# 3) Одобряем CSR и получаем сертификат
kubectl certificate approve "${USER}-csr"
kubectl get csr "${USER}-csr" -o jsonpath='{.status.certificate}' | base64 -d > "${WORKDIR}/${USER}.crt"

echo "Сертификат пользователя сохранён в ${WORKDIR}/${USER}.crt"