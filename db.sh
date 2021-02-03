#!/bin/bash
NEW_ROOT_PASS=$(</home/ec2-user/sql.root.password)
until [[ ${PROJ_NAME} =~ ^[a-zA-Z0-9_-]+$ && ${PROJ_EXISTS} == '0' && ${#PROJ_NAME} -lt 16 ]]; do
	read -rp "Project name: " -e PROJ_NAME
	PROJ_EXISTS=$(grep -c -E "^### Project ${PROJ_NAME}\$" "/home/ec2-user/Caddyfile")
	if [[ ${PROJ_EXISTS} == '1' ]]; then
		echo "Project already exists!!"
	fi
done

# STEP 1.2 type the following
mysql -uroot -p${NEW_ROOT_PASS} <<EOF
CREATE DATABASE ${PROJ_NAME} DEFAULT CHARACTER SET = 'utf8mb4' DEFAULT COLLATE = 'utf8mb4_0900_ai_ci';
CREATE USER '${PROJ_NAME}'@'localhost' IDENTIFIED BY '${PROJ_NAME}.UNIPASS.local.0';
GRANT SHOW VIEW, LOCK TABLES, CREATE, EVENT, EXECUTE, INSERT, DROP, INDEX, ALTER ROUTINE, SELECT, TRIGGER, UPDATE, ALTER, CREATE TEMPORARY TABLES, DELETE, GRANT OPTION, CREATE VIEW, REFERENCES, CREATE ROUTINE ON ${PROJ_NAME}.* TO '${PROJ_NAME}'@'localhost';
ALTER USER '${PROJ_NAME}'@'localhost' IDENTIFIED WITH mysql_native_password BY '${PROJ_NAME}.UNIPASS.local.0';
FLUSH PRIVILEGES;
quit
EOF

echo -e "\n### Project ${PROJ_NAME}
localhost
	reverse_proxy 127.0.0.1:8055" >>"/home/ec2-user/Caddyfile"

echo "
your generated database is: ${PROJ_NAME}
your generated user is: ${PROJ_NAME}
user generated password is: ${PROJ_NAME}.UNIPASS.local.0
"