#!/bin/bash
function setup() {

	# Check for root
	if [ "${EUID}" -ne 0 ]; then
		echo "You need to run this script as root"
		exit 1
	fi

	echo <<EOF
press any key to start installation:
	- mysql 8 (automatically secured)
	- node.js
	- pm2
	- firewalld
	- caddy
	- 1GB swap space
	- directus project in home
EOF
	echo "Setting up database"
	sudo yum install https://dev.mysql.com/get/mysql80-community-release-el7-3.noarch.rpm -y
	sudo amazon-linux-extras install epel -y
	sudo yum install mysql-community-server -y
	sudo systemctl enable --now mysqld

	OLD_ROOT_PASS=$(sudo grep 'temporary password' /var/log/mysqld.log | grep -o 'root@localhost: .*' | cut -d ' ' -f 2)
	NEW_ROOT_PASS=$(tr -dc 'A-Za-z0-9*+-' </dev/urandom | head -c 20)
	echo "detected temporary password: ${OLD_ROOT_PASS}"
	echo "generated root password: ${NEW_ROOT_PASS}"

	yum install expect -y

	SECURE_MYSQL=$(expect -c "

set timeout 10
spawn mysql_secure_installation

expect "Enter password for user root:"
send "$OLD_ROOT_PASS\r"

expect "Set root password?"
send "y\r"

expect "New password:"
send "$NEW_ROOT_PASS\r"

expect "Re-enter new password:"
send "$NEW_ROOT_PASS\r"

expect "Remove anonymous users?"
send "y\r"

expect "Disallow root login remotely?"
send "y\r"

expect "Remove test database and access to it?"
send "y\r"

expect "Reload privilege tables now?"
send "y\r"
expect eof
")

	echo "$SECURE_MYSQL"

	echo "Setting up server node, pm2, firewall, caddy"
	curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | bash
	. ~/.nvm/nvm.sh
	nvm install node
	node -e "console.log('Running Node.js ' + process.version)"
	npm install pm2 -g
	sudo yum install yum-plugin-copr -y
	sudo yum copr enable @caddy/caddy -y
	sudo yum install caddy -y
	sudo yum install firewalld -y
	sudo systemctl enable firewalld --now
	systemctl status firewalld
	sudo firewall-cmd --add-service=http --permanent
	sudo firewall-cmd --add-service=https --permanent
	sudo firewall-cmd --reload

	echo "Setting up swap memory"
	sudo dd if=/dev/zero of=/swapfile bs=128M count=8
	sudo chmod 600 /swapfile
	sudo mkswap /swapfile
	sudo swapon /swapfile
	sudo swapon -s
	sudo sh -c "echo /swapfile swap swap defaults 0 0 >> /etc/fstab"
	free

	touch /home/ec2-user/Caddyfile
	echo "generated mysql root password: ${NEW_ROOT_PASS}"
	touch /home/ec2-user/mysql.root.password
	echo "$NEW_ROOT_PASS" > "/home/ec2-user/mysql.root.password"
}

function addProject() {

	NEW_ROOT_PASS=$(cat /home/ec2-user/mysql.root.password)
	until [[ ${PROJ_NAME} =~ ^[a-zA-Z0-9_-]+$ && ${PROJ_EXISTS} == '0' && ${#PROJ_NAME} -lt 16 ]]; do
		read -rp "Project name: " -e PROJ_NAME
		PROJ_EXISTS=$(grep -c -E "^### Project ${PROJ_NAME}\$" "/home/ec2-user/Caddyfile")
		if [[ ${PROJ_EXISTS} == '1' ]]; then
			echo "Project already exists!!"
		fi
	done

	# STEP 1.2 type the following
	mysql -uroot -p${NEW_ROOT_PASS} <<<EOF
CREATE DATABASE ${PROJ_NAME} DEFAULT CHARACTER SET = 'utf8mb4' DEFAULT COLLATE = 'utf8mb4_0900_ai_ci';
CREATE USER '${PROJ_NAME}'@'localhost' IDENTIFIED BY '${PROJ_NAME}.unipass.local';
GRANT SHOW VIEW, LOCK TABLES, CREATE, EVENT, EXECUTE, INSERT, DROP, INDEX, ALTER ROUTINE, SELECT, TRIGGER, UPDATE, ALTER, CREATE TEMPORARY TABLES, DELETE, GRANT OPTION, CREATE VIEW, REFERENCES, CREATE ROUTINE ON '${PROJ_NAME}'.* TO '${PROJ_NAME}'@'localhost';
FLUSH PRIVILEGES;
quit
EOF

	echo "your generated database is: ${PROJ_NAME}"
	echo "your generated user is: ${PROJ_NAME}"
	echo "user generated password is: ${PROJ_NAME}.unipass.local"

	npx create-directus-project ${PROJ_NAME}
	 
	echo "Type the following npm action to package.json ;   \"start\": \"npx directus start\""

	pm2 start npm --name "${PROJ_NAME}" -- start

	echo -e "\n### Project ${PROJ_NAME}
	localhost
		reverse_proxy 127.0.0.1:8055" >>"/home/ec2-user/Caddyfile"

	echo "Type caddy run to get started"

	echo "Setup finished"
	IPV4=$(ip -4 addr | sed -ne 's|^.* inet \([^/]*\)/.* scope global.*$|\1|p' | head -1)
	IPV6=$(ip -6 addr | sed -ne 's|^.* inet6 \([^/]*\)/.* scope global.*$|\1|p' | head -1)
	echo "detected public IPV4: ${IPV4}"
	echo "detected public IPV6: ${IPV6}"
}

# Check if Caddy is already created (aws has just been set up)
if [[ -e /home/ec2-user/Caddyfile ]]; then
	addProject
else
	setup
	addProject
fi
