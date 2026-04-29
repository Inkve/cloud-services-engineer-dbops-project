# dbops-project
Исходный репозиторий для выполнения проекта дисциплины "DBOps"

Создайте нового пользователя PostgreSQL и выдайте ему права на все таблицы в базе store
```sql
CREATE DATABASE store;
CREATE USER "system_user" WITH PASSWORD 'system_password';
ALTER DATABASE store OWNER TO "system_user";
```
