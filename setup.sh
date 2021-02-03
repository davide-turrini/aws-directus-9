#!/bin/bash
echo "Setting up database"
sudo yum install https://dev.mysql.com/get/mysql80-community-release-el7-3.noarch.rpm -y
sudo amazon-linux-extras install epel -y
sudo yum install mysql-community-server -y
sudo systemctl enable --now mysqld

OLD_ROOT_PASS=$(sudo grep 'temporary password' /var/log/mysqld.log | grep -o 'root@localhost: .*' | cut -d ' ' -f 2)
NEW_ROOT_PASS=${OLD_ROOT_PASS}$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 6)
echo "detected temporary password: ${OLD_ROOT_PASS}"

# STEP 1.2 type the following
mysql -uroot -p${OLD_ROOT_PASS} --connect-expired-password <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${NEW_ROOT_PASS}';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
quit
EOF

echo "Setting up server node, pm2, firewall, caddy"
curl -sL https://rpm.nodesource.com/setup_15.x | sudo bash -
sudo yum install -y nodejs
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

touch /home/ec2-user/Caddyfile
touch /home/ec2-user/sql.root.password
echo "$NEW_ROOT_PASS" > "/home/ec2-user/sql.root.password"
echo "your sql root password: ${NEW_ROOT_PASS}"