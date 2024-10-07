FROM mysql:8.0.33
LABEL "Project"="Aprofile"
LABEL "Author"="Ayobami"

ENV MYSQL_ROOT_PASSWORD="host123"
ENV MYSQL_DATABASE="accounts"


ADD db_backup.sql docker-entrypoint-initdb.d/db_backup.sql
