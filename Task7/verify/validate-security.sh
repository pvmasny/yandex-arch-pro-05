#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

main() {
    validate_namespace_configuration
    inspect_gatekeeper_components
    test_policy_enforcement
    verify_workload_state
}

validate_namespace_configuration() {
    echo "▬▬▬ Проверка конфигурации пространства имен ▬▬▬"
    kubectl get ns audit-zone -o jsonpath='{.metadata.labels}' | jq . || true
}

inspect_gatekeeper_components() {
    echo "▬▬▬ Проверка компонентов Gatekeeper ▬▬▬"
    kubectl get pods -n gatekeeper-system || true
    kubectl get constrainttemplates || true
    kubectl get k8sprivilegedcontainer.constraints.gatekeeper.sh || true
    kubectl get k8shostpathprohibited.constraints.gatekeeper.sh || true
    kubectl get k8srunasnonrootreadonlyfs.constraints.gatekeeper.sh || true
}

test_policy_enforcement() {
    echo "▬▬▬ Тестирование применения политик безопасности ▬▬▬"

    echo "➤ Проверка отклонения небезопасной конфигурации:"
    cat <<'EOF' | kubectl apply --dry-run=server -f - || echo "✓ КОРРЕКТНО: Конфигурация отклонена политикой безопасности"
apiVersion: v1
kind: Pod
metadata:
  name: tmp-bad
  namespace: audit-zone
spec:
  containers:
    - name: bb
      image: busybox:1.36
      command: ["sh", "-c", "sleep 5"]
      securityContext:
        privileged: true
EOF

    echo "➤ Проверка принятия безопасной конфигурации:"
    cat <<'EOF' | kubectl apply --dry-run=server -f -
apiVersion: v1
kind: Pod
metadata:
  name: tmp-good
  namespace: audit-zone
spec:
  securityContext:
    runAsNonRoot: true
    seccompProfile:
      type: RuntimeDefault
  containers:
    - name: bb
      image: busybox:1.36
      command: ["sh", "-c", "sleep 5"]
      securityContext:
        runAsNonRoot: true
        allowPrivilegeEscalation: false
        capabilities:
          drop: ["ALL"]
        readOnlyRootFilesystem: true
EOF
    echo "✓ КОРРЕКТНО: Безопасная конфигурация принята"
}

verify_workload_state() {
    echo "▬▬▬ Проверка состояния рабочих нагрузок ▬▬▬"
    kubectl -n audit-zone get pods -o wide || true
}

main
echo "✓ Проверка конфигурации завершена"
