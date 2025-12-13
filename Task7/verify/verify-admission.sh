#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

main() {
    log_step "Настройка пространства имен с политикой безопасности 'restricted'"
    kubectl apply -f "${SCRIPT_DIR}/01-create-namespace.yaml"

    log_step "Установка шаблонов ограничений Gatekeeper"
    kubectl apply -f "${SCRIPT_DIR}/gatekeeper/constraint-templates/"

    log_step "Применение политик ограничений Gatekeeper"
    kubectl apply -f "${SCRIPT_DIR}/gatekeeper/constraints/"

    execute_negative_validation
    execute_positive_validation
    validate_workload_status
}

log_step() {
    echo "➤ $1"
}

execute_negative_validation() {
    echo "▬▬▬ Проверка отклонения небезопасных конфигураций ▬▬▬"
    local validation_result=0
    for manifest_file in "${SCRIPT_DIR}"/insecure-manifests/*.yaml; do
        local manifest_name
        manifest_name="$(basename "$manifest_file")"
        set +e
        local command_output
        command_output="$(kubectl apply -f "$manifest_file" 2>&1)"
        validation_result=$?
        set -e
        if [[ $validation_result -eq 0 ]]; then
            echo "❌ ОШИБКА: ${manifest_name} был принят, но должен быть отклонен"
            echo "Детали:"
            echo "$command_output"
            exit 1
        else
            echo "✓ КОРРЕКТНО: ${manifest_name} отклонен как и ожидалось"
            echo "Сообщение: $(echo "$command_output" | head -n 2)"
        fi
    done
}

execute_positive_validation() {
    echo "▬▬▬ Проверка принятия безопасных конфигураций ▬▬▬"
    for manifest_file in "${SCRIPT_DIR}"/secure-manifests/*.yaml; do
        local manifest_name
        manifest_name="$(basename "$manifest_file")"
        kubectl apply -f "$manifest_file"
        echo "✓ ПРИНЯТО: ${manifest_name} успешно применен"
    done
}

validate_workload_status() {
    echo "▬▬▬ Проверка состояния рабочих нагрузок ▬▬▬"
    sleep 3
    kubectl -n audit-zone get pods -o wide
}

main
echo "✓ Все проверки завершены успешно"
