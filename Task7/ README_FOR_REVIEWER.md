# 1. Установка OPA Gatekeeper
```shell
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/release-3.14/deploy/gatekeeper.yaml
kubectl wait --for=condition=Ready pod -l control-plane=controller-manager -n gatekeeper-system --timeout=300s
```

# 2. Создание namespace
```shell
kubectl apply -f 01-create-namespace.yaml
```

# 3. Настройка OPA Gatekeeper
```shell
kubectl apply -f gatekeeper/constraint-templates/
kubectl apply -f gatekeeper/constraints/
```

# 4. Проверка
```shell
chmod +x verify/verify-admission.sh
./verify/verify-admission.sh
chmod +x verify/validate-security.sh
./verify/validate-security.sh
```
