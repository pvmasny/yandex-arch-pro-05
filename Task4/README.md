| Роль  | Права роли | Группы пользователей |
| --- | --- | --- |
| admin-role | Полный доступ к кластеру | DevOps |
| dev-role | Просмотр ресурсов pods, services, deployments, configmaps  | Разработчики |

# Инструкция
1. Создание пользователя developer и admin:
   * ./user.sh developer developer
   * ./user.sh admin admin
2. Создание ролей: ./r.sh
3. Связь пользователя и ролей: ./rb.sh 