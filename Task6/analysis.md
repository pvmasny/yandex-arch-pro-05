# Отчёт по результатам анализа Kubernetes Audit Log

## Подозрительные события

1. Доступ к секретам:
   - Кто: system:serviceaccount:kube-system:daemon-set-controller
   - Где: В namespace kube-system
   - Почему подозрительно: Получение secrets в системном namespace

2. Привилегированные поды:
   - Кто: minikube-user -- входит в группы system:masters и system:authenticated
   - Комментарий: Создан system:masters.  system:masters имеет полный доступ к кластеру. Стоит пересмотреть привелегии для данный операции

3. Использование kubectl exec в чужом поде:
   - Кто: minikube-user
   - Что делал: В kube-system исключить pods/exec из Role

4. Создание RoleBinding с правами cluster-admin:
   - Кто: minikube-user
   - К чему привело: ServiceAccount monitoring (в namespace secure-ops) получил права cluster-admin. А значит получает полный доступ к кластеру.



5. Удаление audit-policy.yaml:
   - Кто: minikube-user
   - Возможные последствия: После удаления политики аудита kube-apiserver перестанет генерировать события аудита.

## Вывод

1. Необоснованный доступ к секретам
Сервисный аккаунт daemon-set-controller в kube-system получал доступ к secrets — это потенциально опасно, так как системные секреты могут содержать чувствительные данные (ключи, токены).
2. Избыточные привилегии пользователей
minikube-user (в группе system:masters) выполнял операции, требующие переоценки:
* создание привилегированных подов;
* использование kubectl exec в чужом поде (kube-system);
* назначение роли cluster-admin сервисному аккаунту monitoring.
3. Отключение аудита
Удаление audit-policy.yaml привело к потере возможности отслеживать действия в кластере, что:
* затрудняет расследование инцидентов;
* снижает прозрачность операций;
* увеличивает риски незамеченных атак.
