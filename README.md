<h1 align="center">DIRECTUS 9 @ AWS EC2</h1>
<p align="center">And how to get it running on Amazon Linux 2 AMI</p>

## What are we talking about
We are talking about a simple to do list to get Directus 9 running on a EC2 istance. Free and clean.

### First of all..

type this in your ssh terminal in order to get all the 
resources listed below installed.

```
curl https://raw.githubusercontent.com/davide-turrini/aws_cms/master/setup.sh > setup.sh && chmod +x setup.sh && sudo ./setup.sh && rm -rf setup.sh
```


 - Mysql 8, secured
 - Node.js 15.x
 - PM2
 - Caddy as a reverse proxy
 - Firewalld to allow HTTP/HTTPS only


##### (AND IF YOU RUN OUT OF RAM ..)

type this in your ssh terminal in order to get 1GB more of swap memory

```
curl https://raw.githubusercontent.com/davide-turrini/aws_cms/master/swap.sh > swap.sh && chmod +x swap.sh && sudo ./swap.sh && rm -rf swap.sh
```

#### PREPARE A DATABASE FOR EVERY PROJECT

before creating a directus project make a database and a user by typing the following.. 
```
curl https://raw.githubusercontent.com/davide-turrini/aws_cms/master/db.sh > db.sh && chmod +x db.sh && sudo ./db.sh && rm -rf db.sh
```

#### CREATE YOUR PROJECT

- type this to create the directus project: 
    
    ```
    npx create-directus-project <your project name!>
    ```

- remember to add this script in your package.json

    ```
        "start": "npx directus start"
    ```

- type this to link with your PM2 dashboard
    
    ```
        pm2 start npm --name "<your project name!>" -- start
    ```

- type this to run reverse proxy on port 80

    ```
    caddy run
    ```
  
Congrats! You have finished. A Caddyfile should have been added in your home directory!
You can edit it in order to manage all the configurations for your project!