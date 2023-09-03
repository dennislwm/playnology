# playnology

Starter project for your Synology NAS.

<!-- TOC -->

- [playnology](#playnology)
- [Introduction](#introduction)
  - [Purpose](#purpose)
  - [Audience](#audience)
  - [Terms and Acronyms](#terms-and-acronyms)
- [System Overview](#system-overview)
  - [Benefits and Values](#benefits-and-values)
  - [Limitations](#limitations)
- [User Personas](#user-personas)
  - [RACI Matrix](#raci-matrix)
- [Requirements](#requirements)
  - [Synology](#synology)
    - [Changing SSH Password](#changing-ssh-password)
      - [Enabling SSH](#enabling-ssh)
      - [Temporarily Enabling Telnet](#temporarily-enabling-telnet)
    - [Connecting via SSH](#connecting-via-ssh)
    - [Installing Portainer](#installing-portainer)
    - [Adding Docker container](#adding-docker-container)
      - [Using Docker Compose](#using-docker-compose)
    - [Prevent Synology Listening on Port 80/443](#prevent-synology-listening-on-port-80443)
    - [Dangerous](#dangerous)
    - [Using Portainer](#using-portainer)
      - [Basic Container Settings](#basic-container-settings)
      - [Advanced Container Settings](#advanced-container-settings)
    - [NGINX Proxy Manager](#nginx-proxy-manager)
      - [Enabling Port Forwarding on Router](#enabling-port-forwarding-on-router)
  - [ZeroTier One](#zerotier-one)
    - [iPhone](#iphone)
- [Installation and Configuration](#installation-and-configuration)
  - [Installing Ansible](#installing-ansible)
  - [Setting up LDAP on your Synology NAS](#setting-up-ldap-on-your-synology-nas)
  - [Setting up configuration.yml for Authelia stack](#setting-up-configurationyml-for-authelia-stack)
  - [Install and configure ZeroTier One on iPhone](#install-and-configure-zerotier-one-on-iphone)
- [Execution](#execution)
  - [Creating a basic inventory file](#creating-a-basic-inventory-file)
  - [Running your first Ad-Hoc Ansible command](#running-your-first-ad-hoc-ansible-command)
  - [Your first Ansible playbook](#your-first-ansible-playbook)
  - [Docker-compose Deployment with SSH](#docker-compose-deployment-with-ssh)
  - [Docker-compose Deployment with Portainer Stack](#docker-compose-deployment-with-portainer-stack)
  - [Docker-compose Deployment with Portainer Containers](#docker-compose-deployment-with-portainer-containers)
  - [Access and bookmark container apps from NAS on iPhone](#access-and-bookmark-container-apps-from-nas-on-iphone)
- [Logging](#logging)
- [Monitoring](#monitoring)
- [Updating](#updating)
  - [Manually updating Disk Station Manager DSM](#manually-updating-disk-station-manager-dsm)
  - [Manually installing additional RAM in Synology DS920+](#manually-installing-additional-ram-in-synology-ds920)
- [Troubleshooting](#troubleshooting)
  - [Using SSH connection type with passwords](#using-ssh-connection-type-with-passwords)
  - [Too many authentication failure](#too-many-authentication-failure)
  - [You are still asked by SSH to enter a password](#you-are-still-asked-by-ssh-to-enter-a-password)
  - [Missing sudo password](#missing-sudo-password)
  - [Error Start container zt failed](#error-start-container-zt-failed)
- [References](#references)

<!-- /TOC -->

---
# 1. Introduction
## 1.1. Purpose

This document describes the Synology NAS automation and manual services that is provided for DevSecOps engineers.

## 1.2. Audience

The audience for this document includes:

* Mobile User who will install, configure and enable **ZeroTier One** app on their iPhone to access the container applications hosted on Synology NAS.

* DevSecOps Engineer who will install, configure and update the Synology NAS services to ensure continuous uptime and backup redundancy.

## 1.3. Terms and Acronyms

| Term |      Definition      |
|:----:|:--------------------:|
| DSM  | Disk Station Manager |

---
# 2. System Overview
## 2.1. Benefits and Values

## 2.2. Limitations

1. DSM 7.2 has stopped support for Docker.

---
# 3. User Personas
## 3.1 RACI Matrix

|           Category           |                       Activity                        | Mobile User | DSO Engineer |
|:----------------------------:|:-----------------------------------------------------:|:-----------:|:------------:|
| Installation & Configuration |                  Installing Ansible                   |             |     R,A      |
| Installation & Configuration |         Setting up LDAP on your Synology NAS          |             |     R,A      |
| Installation & Configuration |   Setting up `configuration.yml` for Authelia stack   |             |     R,A      |
|          Execution           |            Creating a basic inventory file            |             |     R,A      |
|          Execution           |       Running your first Ad-Hoc Ansible command       |             |     R,A      |
|          Execution           |              Your first Ansible playbook              |             |     R,A      |
|          Execution           |          Docker-compose Deployment with SSH           |             |     R,A      |
|          Execution           |    Docker-compose Deployment with Portainer Stack     |             |     R,A      |
|          Execution           |  Docker-compose Deployment with Portainer Containers  |             |     R,A      |
|           Updating           |                 Manually updating DSM                 |             |     R,A      |
| Installation & Configuration |     Install and configure ZeroTier One on iPhone      |     R,A     |      C       |
|          Execution           | Access and bookmark container apps from NAS on iPhone |     R,A     |              |
|       Troubleshooting        |            Error Start container zt failed            |      I      |     R,A      |

---
# 4. Requirements
## 4.1. Synology
### 4.1.1. Changing SSH Password

#### Enabling SSH

You can enable SSH service from the `Control Panel`. Go to `Terminal & SNMP` and check the box `Enable SSH service` and click `Apply`.

After enabling SSH service, you will find out that you are unable to login with the admin password on the Synology web interface. We will need to temporarily enable Telnet service to fix this problem.

#### Temporarily Enabling Telnet

Under the previous `Terminal & SNMP`, check the box `Enable Telnet service` and click `Apply`. You have to connect to both Telnet and SSH on the LAN because it doesn't work with Quickconnect.

On your iPhone, download the app iTerminal. Open the app and create a Telnet connection specifying your `[PRIVATE_IP]` address on port `23`.

Login using `admin` and same password as your Synology web interface. Type the following command to change the SSH password:

```bash
$ sudo synouser --setpw admin [PASSWORD]
```

If it doesn't work the first time, try again. After changing the password, you should be able to SSH to your Synology.

Return to your Synology `Control Panel`, and disable the Telnet service.

*Warning: Changing the `admin` password using Task Scheduler did not work.*

### 4.1.2. Connecting via SSH

Using the app iTerminal, create an SSH connection specifying your IP address on port 22. Login using admin and your password, and type EXACT:

```bash
$ sudo ln -s /var/run/docker.sock /volume1/docker/docker.sock
```

*Warning: Even after creating the symlink you cannot create the container from the Docker UI. This is because symlinks are not listed when trying to create a volume/file link.*

### 4.1.3. Installing Portainer

The Synology Docker UI is nice but lacks some functionality such as Stacks, Templates, etc. Portainer will run seamlessly along side the Synology Docker UI.

First make a folder on your Synology Web Interface to hold the portainer data, using File Station, i.e. /`DBDock/docker/portainer`.

However before we can install **Portainer**, we need to login via SSH as `admin` (password is same as your Synology Web Interface).

```bash
ssh admin:[PASSWORD]@[PRIVATE_IP]
```

Now run the following command to grab the Portainer image.

```bash
docker run -d -p 8000:8000 -p 9000:9000 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v /volume1/docker/portainer:/data portainer/portainer
```

*Warning: Do not change `volume1` as it is the EXACT name of DBDock.*

Now check to see if it worked, you need to access the Portainer container from your LAN, i.e. [PRIVATE_IP], on port 9000. Create the admin user and password.

Once logged in, select the **Local** environment and press the **Connect** button. You should be able to see a Dashboard of all your Docker files.

### 4.1.4. Adding Docker container

There are two methods to pull a new Docker image and add a running container:

1. Using Docker Compose
2. Using Portainer

#### Using Docker Compose

First, login to your Synology via SSH as `admin` (password is same as your Synology Web Interface). Your `$HOME` directory should be `/var/services/homes/admin`.

Create a folder to store your docker-compose files and navigate into it.

```bash
mkdir -p docker-compose/nginxpm
cd docker-compose/nginxpm
```

Create a `docker-compose.yml` file and copy & paste the following code and save it.

```
version: "3"
services:
  app:
    image: 'jc21/nginx-proxy-manager:latest'
    restart: always
    ports:
      # Public HTTP Port:
      - '80:80'
      # Public HTTPS Port:
      - '443:443'
      # Admin Web Port:
      - '81:81'
      # Default Administrator User
      #   URL: http://localhost:81
      #   Email: admin@example.com
      #   Password: changeme
    environment:
      # These are the settings to access your db
      DB_MYSQL_HOST: "db"
      DB_MYSQL_PORT: 3306
      DB_MYSQL_USER: "npm"
      DB_MYSQL_PASSWORD: "npm"
      DB_MYSQL_NAME: "npm"
      # If you would rather use Sqlite uncomment this
      # and remove all DB_MYSQL_* lines above
      # DB_SQLITE_FILE: "/data/database.sqlite"
      # Uncomment this if IPv6 is not enabled on your host
      # DISABLE_IPV6: 'true'
    volumes:
      - vol_data:/data
      - vol_letsencrypt:/etc/letsencrypt
    depends_on:
      - db
    networks:
      - net_public
      - net_private
  db:
    image: 'jc21/mariadb-aria:latest'
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: 'npm'
      MYSQL_DATABASE: 'npm'
      MYSQL_USER: 'npm'
      MYSQL_PASSWORD: 'npm'
    volumes:
      - vol_mysql:/var/lib/mysql
    networks:
      - net_private

volumes:
  vol_data:
  vol_letsencrypt:
  vol_mysql:
  # Named volumes are stored in a part of the host filesystem
  # which is managed by Docker (/volume1/@docker/volumes/ on Synology)
  # Docker appends [FOLDER] name to named volumes.
  #   nginxpm_vol_data
  #   nginxpm_vol_letsencrypt
  #   nginxpm_vol_mysql

networks:
  net_public:
  net_private:
  # Docker appends [FOLDER] name to named networks.
  #   nginxpm_net_public
  #   nginxpm_net_private
```

Run the `docker-compose` command within the same folder.

```
sudo docker-compose up -d
```

### 4.1.5. Prevent Synology Listening on Port 80/443

Synology DSM is configured to run on both default ports 5000 and 5001. However, it's listening on ports 80 and 443 for redirection.

In order to free ports 80 and 443, we will replace these ports with 82 and 444, respectively.

```bash
sudo sed -i -e 's/80/82/' -e 's/443/444/' /usr/syno/share/nginx/server.mustache /usr/syno/share/nginx/DSM.mustache /usr/syno/share/nginx/WWWService.mustache
sudo synoservicecfg --restart nginx
```

### 4.1.6. Dangerous

Alternatively, if we want to stop NGINX server we won't need to replace ports 80 and 443.

Stop the NGINX server.

```bash
sudo synoservicecfg --disable nginx
sudo synoservicecfg --hard-stop nginx
```

Restart both the NGINX and DSM servers.

```bash
sudo synoservicecfg --enable nginx
sudo synoservicecfg --restart nginx
sudo synoservice --enable DSM
sudo synoservice --restart DSM
```

*Warning: Synology DSM depends on NGINX server.*

### 4.1.7. Using Portainer

Access the Portainer container from your LAN, i.e. [PRIVATE_IP], on port 9000, and login as `admin`.

#### Basic Container Settings

Click on the side menu `Containers`, then click on `+ Add Container`.

Enter both the container and image names. For example, `objTeedy` and `jdreinhardt/teedy:latest`.

Click on `+ publish a new network port` and enter host port `8080` and container port `8080`. Ensure `TCP` is selected.

#### Advanced Container Settings

Click on `Volumes` and then `+ map additional volume` button.

Map container path `/data` to host volume `teedy_vol_data`.

Click on `Network` and then select `nginxpm_net_public`.

Click on `Deploy the container`.

### 4.1.8. NGINX Proxy Manager

#### Enabling Port Forwarding on Router

You may need to enable port forwarding on both your Google Home WiFi and router.

---
## 4.2. ZeroTier One

### iPhone

[Download on the App Store](https://www.zerotier.com/download/)

---
# 5. Installation and Configuration
## 5.1. Installing Ansible

**Ansible**'s only real dependency is Python. Once Python is installed, the simplest way to get Ansible running is to use `pip`.

```
pip install ansible
```

> You must enable SSH remote connection on your Synology NAS before running Ansible commands. You can follow the steps in this article:
>
> [Configure the SSH server on your Synology NAS](https://flatpacklinux.com/2020/01/07/configure-the-ssh-server-on-your-synology-nas)

## 5.2. Setting up LDAP on your Synology NAS

This runbook should be performed by the DevSecOps.

The benefit of running LDAP on your server is single sign-on (SSO). For services that do not have any login, your LDAP service will protect those services, while for services that have their own login feature, your LDAP service will provide one login for all of them.

1. Navigate to your Synology NAS Console > Package Center.

2. Find and install **LDAP Server**.

3. Open LDAP Server > Settings > click **Enable LDAP server** checkbox to enable it.

4. Enter the following details:
  - For FQDN, enter your LDAP server name, e.g. `dbdock.watertown`.
  - For Password, enter your LDAP password, this is NOT the same as your DSM account.

5. Click **Apply**.

6. Under Authentication Information, you should see that your **Base DN** and **Bind DN** are now configured.

## 5.3. Setting up `configuration.yml` for Authelia stack

This runbook should be performed by the DevSecOps.

Before we can fire up an Authelia stack on Portainer, we need to have its `configuration.yml` file ready and configured towards your Synology NAS environment.

1. Choose a custom location on your Synology NAS where your Authelia config file will be stored, we can store it under the Synology Docker root folder `/volume1/docker`.

2. Copy the [`config.template.yml`](https://github.com/authelia/authelia/blob/master/config.template.yml) file to your custom location, e.g. `/volume1/docker/authelia/configuration.yml`.

3. Edit the `configuration.yml` to your Synology NAS environment:
  - For **`jwt_secret`**: set the environment variable `AUTHELIA_JWT_SECRET_FILE` to `/secrets/JWT_SECRET` file with a long random value.
  - For **`totp.issuer`**: enter your FQDN, e.g. `dbdock.watertown`.
  - Under **`authentication_backend.ldap`**,
    - For **`url`**: enter your NAS IP e.g. `ldap://192.xx.xx.xx`.
    - For **`base_dn`**: enter your LDAP **Base DN** configuration.
    - For **`user`**: enter your LDAP **Bind DN** configuration.
    - For **`password`**: set the environment variable `AUTHELIA_AUTHENTICATION_BACKEND_LDAP_PASSWORD_FILE` to `/secrets/AUTHENTICATION_BACKEND_LDAP_PASSWORD` file with your LDAP admin password.
    - For **`users_filter`**: enter `(&({username_attribute}={input})(objectClass=person))`.
  - Under **`access_control.rules[*]`**,
    - For **`domain`**: enter your domain wildcard, e.g. `*.dbdock.watertown`.
    - For **`subject`**: enter which users to apply rules to, e.g. `user:root`.
  - Under **`session`,
    - For **`domain`**, enter your FQDN, e.g. `dbdock.watertown`.
    - For **`secret`**, set the environment variable `AUTHELIA_SESSION_SECRET_FILE` to `/secrets/SESSION_SECRET` file with a long random value.
    - For **`redis.host`**, enter your NAS IP e.g. `192.xx.xx.xx`.
    - For **`redis.database_index`**, enter an index for your Redis database, e.g. use any integer [0..], where default is 0.
  - Under **`storage.mysql`**,
    - For **`encryption_key`**: set the environment variable `AUTHELIA_STORAGE_ENCRYPTION_KEY_FILE` to `/secrets/STORAGE_ENCRYPTION_KEY` file with a long random value of at least 20 chars.
    - For **`host`**, enter your NAS IP e.g. `192.xx.xx.xx`.
    - For **`port`**, enter `3306`.
    - For **`database`**, enter your custom database name that you have created, e.g. `authelia`.
    - For **`username`**, enter your custom database user that you have created, e.g. `authelia`.
    - For **`password`**, set the environment variable `AUTHELIA_STORAGE_MYSQL_PASSWORD_FILE` to `/secrets/STORAGE_MYSQL_PASSWORD` file with your custom database password that you have configured.
  - Under **`notifier.smtp`**,
    - For **`host`**, enter `smtp.gmail.com`.
    - For **`port`**, enter `587`
    - For **`username`**, enter your Gmail user that you have created.
    - For **`password`**, set the environment variable `AUTHELIA_NOTIFIER_SMTP_PASSWORD_FILE` to `/secrets/NOTIFIER_SMTP_PASSWORD` file with your **Gmail application password** that you have configured.
    - For **`sender`**, enter your custom sender, e.g. `Authelia <authelia@dbdock.watertown>`.

```yml
.
.
.
host: 0.0.0.0 # do not change this!
port: 9091 # do not change this, this is Authelia internal port
.
.
theme: light # there are 3 themes so choose one you like
.
.
.
jwt_secret: xxxxxxxxxxxx # generate a long random key value
.
.
.
totp:
  issuer: yourdomain.com # enter what you want to see when using 2FA
  period: 30
  skew: 1
.
.
.
authentication_backend:
  ldap:
    implementation: custom
    url: ldap://yourNASIP
    start_tls: false
    base_dn: dc=blackvoid,dc=home # enter the values from the LDAP config
    additional_users_dn: cn=users
    additional_groups_dn: cn=groups
    groups_filter: (&(uniquemember={dn})(objectclass=groupOfUniqueNames))
    user: uid=admin,cn=users,dc=blackvoid,dc=home # your LDAP parameters
    password: xxxxxxxxxxx # LDAP Admin password
.
.
.
access_control:
  default_policy: deny
  networks:
    - name: 'internal'
      networks:
        - '192.168.86.0/24'
  rules:
    ## Rules applied to user 'admin'
    - domain: app1.yourdomain.com
      subject: "user:admin"
      policy: two_factor
    - domain: app1.yourdomain.com
      subject: "user:admin"
      policy: one_factor
      networks:
        - 'internal'
.
.
.
session:
  name: authelia_session
  domain: yourdomain.com
  same_site: lax
  secret: xxxxxxxx # generate a long random key value
.
.
.
  redis:
    host: NASIPAddres # something like 10.20.30.35
    port: 6379 # port for REDIS docker contianer
    database_index: 0 # change this if you already use REDIS for something
.
.
.
storage:
  mysql:
    host: yourNASIP
    port: 3306 # mysql docker container port
    database: authelia # change to the name you have configured
    username: authelia_user # change to the user you have configured
    password: xxxxxxxxxxxx # change to the password you have configured
.
.
.
notifier:
  smtp:
    username: usernameOfYourMail
    password: xxxxxx
    host: smtp.gmail.com # this is just an example
    port: 587
    sender: sender@domain.com
```

## 5.4. Install and configure ZeroTier One on iPhone

This runbook should be performed by the Mobile User.

1. Download and install the **ZeroTier One** app.

2. Open the app and click `+`.

3. Enter the **Network ID** from your ZeroTier account.
  - Enable Default Route.
  - Enable On Demand (beta).

4. Click on **Add Network**.
  - Check that the Status is `OK`.

---
# 6. Execution
## 6.1. Creating a basic inventory file

Ansible uses an inventory file (basically, a list of servers) to communicate with your servers. Create a file `hosts` in your project root folder and add one server to it:

```yml
[wifi]
192.0.2.5
```

The `wifi` is an arbitrary name for the group of servers you're managing, followed by the IP addresses of your servers, one per line. If you're not using port 22 for SSH, you will need to append it to the address.

---
## 6.2. Running your first Ad-Hoc Ansible command

Now that you've installed Ansible and created an inventory file, it's time to run a command:

```sh
ansible <group> -i ./hosts -m ping -u <user>
```

Ansible assumes you're using a passwordless login for SSH (e.g. you login by entering `ssh <user>@<serverip>`). If you're using a password, add the `-k` flag to Ansible commands (you may need to install the `sshpass` package for this to work).

You can associate a `<user>` with each IP address, thus making your Ansible commands shorter.

```yml
[wifi]
192.0.2.5 ansible_user=admin
```

Alternatively, you can place the `ansible_user` variable under a group `<group>:vars`, which then applies the variables to all servers in that group.

```yml
[wifi]
192.0.2.5

[wifi:vars]
ansible_user=admin
```

The previous command would now be:

```sh
ansible <group> -i ./hosts -m ping
```

---
## 6.3. Your first Ansible playbook

Create a folder `plays/` and add a file `check-linux-system-playbook.yml` in that folder. Copy and paste the following code:

```yml
---
- hosts: all
  become: yes
  tasks:
  - name: Ensure NTP is running
    service: name=ntpd state=started
```

Now that you've created your first Ansible playbook, it is time to run it.

```sh
ansible-playbook -i ./hosts plays/check-linux-system-playbook.yml
```

---
## 6.4. Docker-compose Deployment with SSH

1. Open a local terminal and remote SSH to your Synology NAS.

```sh
ssh admin@IP_ADDRESS
```

2. Navigate to the path `~/docker-compose/paperless`, where HOME folder is `/var/services/homes/admin/`.

3. Run docker-compose with `sudo` privileges.

```sh
sudo docker-compose.yml
```

4. Ensure that the `USERMAP_UID` and `USERMAP_GID` is unused.

```sh
cat /etc/passwd | grep 1000
```

5. Create a paperless admin user.

```sh
docker exec -it paperlessng_webserver_1 python3 /usr/src/paperless/src/manage.py createsuperuser --username=admin --
```

---
## 6.5. Docker-compose Deployment with Portainer Stack

1. Navigate and login to Portainer UI, e.g. http://localhost:9000, then click on **Local**.

2. Click on **Stacks** -> **+ Add stack**.

- Name: paperlessng

Navigate to the section **Build method**, and click on **Upload**, then **Select file**. Select your `docker-compose.yml` file.

```yml
# docker-compose file for running paperless from the Docker Hub.
# This file contains everything paperless needs to run.
# Paperless supports amd64, arm and arm64 hardware.
#
# All compose files of paperless configure paperless in the following way:
#
# - Paperless is (re)started on system boot, if it was running before shutdown.
# - Docker volumes for storing data are managed by Docker.
# - Folders for importing and exporting files are created in the same directory
#   as this file and mounted to the correct folders inside the container.
# - Paperless listens on port 8010.
#
# In addition to that, this docker-compose file adds the following optional
# configurations:
#
# - Instead of SQLite (default), PostgreSQL is used as the database server.
#
# To install and update paperless with this file, do the following:
#
# - Open portainer Stacks list and click 'Add stack'
# - Paste the contents of this file and assign a name, e.g. 'Paperless'
# - Click 'Deploy the stack' and wait for it to be deployed
# - Open the list of containers, select paperless_webserver_1
# - Click 'Console' and then 'Connect' to open the command line inside the container
# - Run 'python3 manage.py createsuperuser' to create a user
# - Exit the console
#
# For more extensive installation and update instructions, refer to the
# documentation.

version: "2"
services:
  broker:
    image: redis:6.0
    restart: unless-stopped
    volumes:
      - vol_redis:/data
    networks:
      - net_private

  db:
    image: postgres:13
    restart: unless-stopped
    volumes:
      - vol_postgres:/var/lib/postgresql/data
    environment:
      POSTGRES_DB: paperless
      POSTGRES_USER: paperless
      POSTGRES_PASSWORD: paperless
    networks:
      - net_private

  webserver:
    image: jonaswinkler/paperless-ng:latest
    restart: unless-stopped
    depends_on:
      - db
      - broker
    ports:
      - 8080:8000
      # URL: http://localhost:8080/
    volumes:
      - vol_data:/usr/src/paperless/data
      - vol_media:/usr/src/paperless/media
      - /var/services/homes/admin/docker-compose/paperless/export:/usr/src/paperless/export
      - /var/services/homes/admin/docker-compose/paperless/consume:/usr/src/paperless/consume
    environment:
      PAPERLESS_REDIS: redis://broker:6379
      PAPERLESS_DBHOST: db
# The UID and GID of the user used to run paperless in the container. Set this
# to your UID and GID on the host so that you have write access to the
# consumption directory.
      USERMAP_UID: 1000
      USERMAP_GID: 1000
# Additional languages to install for text recognition, separated by a
# whitespace. Note that this is
# different from PAPERLESS_OCR_LANGUAGE (default=eng), which defines the
# language used for OCR.
# The container installs English, German, Italian, Spanish and French by
# default.
# See https://packages.debian.org/search?keywords=tesseract-ocr-&searchon=names&suite=buster
# for available languages.
      #PAPERLESS_OCR_LANGUAGES: tur ces
# Adjust this key if you plan to make paperless available publicly. It should
# be a very long sequence of random characters. You don't need to remember it.
      #PAPERLESS_SECRET_KEY: change-me
# Use this variable to set a timezone for the Paperless Docker containers. If not specified, defaults to UTC.
      PAPERLESS_TIME_ZONE: Asia/Singapore
# The default language to use for OCR. Set this to the language most of your
# documents are written in.
      #PAPERLESS_OCR_LANGUAGE: eng
    networks:
      - net_public
      - net_private

volumes:
  vol_redis:
  vol_postgres:
  vol_data:
  vol_media:
  # Named volumes are stored in a part of the host filesystem
  # which is managed by Docker (/volume1/@docker/volumes/ on Synology)
  # Docker appends [FOLDER] name to named volumes.
  #   paperlessng_vol_data

networks:
  net_public:
  net_private:
  # Docker appends [FOLDER] name to named networks.
  #   paperlessng_net_public
  #   paperlessng_net_private
```

3. Open the container `paperless_webserver_1`. Navigate to **Connected networks**, and select a network `bridge`. Then, click **Join network**.

4. Navigate to the **Container status**, and click on **>_ Console**. Then, click **Connect** and type the following command:

```sh
python3 /usr/src/paperless/src/manage.py createsuperuser --username=admin
```

This command will create a superuser `admin`. Enter your email and password when prompted. Type `exit` when done.

5. Navigate to the **Container status**, and click on **Logs**. Check if there are any errors in the log.

---
## 6.6. Docker-compose Deployment with Portainer Containers

1. Navigate and login to Portainer UI, e.g. http://localhost:9000, then click on **Local**.

2. Add volumes for all containers. Click on **Volumes** -> **+ Add volume**.

- Name: paperless_vol_redis

Click **Create the volume**. Do this for all the volumes.

3. Add the database container. Click on **+ Add container** button and enter the database info.

- Name: paperless_redis
- Image: redis:6.0

Navigate to the section **Advanced container settings**, click on **Volumes** -> **+ map additional volume**.

- container: /data
- volume: paperless_vol_redis

Navigate to **Network**, and select `nginxpm_net_private`.

Navigate to **Restart policy**, and select **Unless stopped**.

Click **Deploy the container** and your database container should start. Do this for all the databases.

4. Add the web server container. Click on **+ Add container** button and enter the application info.

- Name: paperless_app
- Image jonaswinkler/paperless-ng:latest

Navigate to the section **Network ports configuration**, click on **+ publish a new network port**.

- host: 8080
- container: 8000

Navigate to the section **Advanced container settings**, click on **Volumes** -> **+ map additional volume**.

- container: /usr/src/paperless/data
- volume: paperless_vol_data

- container: /usr/src/paperless/media
- volume: paperless_vol_media

- container: /usr/src/paperless/export
- volume: /var/services/homes/admin/docker-compose/paperless/export

- container: /usr/src/paperless/consume
- volume: /var/services/homes/admin/docker-compose/paperless/consume

Navigate to **Network**, and select `bridge`. Also, add `nginxpm_net_private`.

Navigate to **Env**, and click on **+ add environment variable**.

- name: PAPERLESS_REDIS
- value: redis://paperless_redis:6379

- name: PAPERLESS_DBHOST
- value: paperless_db

- name: USERMAP_UID
- value: 1000

- name: USERMAP_GID
- value: 1000

Navigate to **Restart policy**, and select **Unless stopped**.

---
## 6.7. Access and bookmark container apps from NAS on iPhone

This runbook should be performed by the Mobile User.

1. On your iPhone, open a browser and type the URL as follows:
  - `ZEROTIER_MANAGED_IP:NAS_PORT`, e.g. `172.29.xxx.xxx:8100`

| Note: Accessing the container app requires both **ZeroTier One** running on your iPhone and NAS.

2. You should see the home page of your container app.

3. Bookmark the page on your browser.

---
# 7. Logging

---
# 8. Monitoring

---
# 9. Updating
## 9.1. Manually updating Disk Station Manager (DSM)

This runbook should be performed by the DevSecOps Engineer.

1. Navigate to your Synology NAS Console > Control Panel > Update & Restore

2. Click on **Download** to download the latest DSM.

3. After download has completed successfully, click on **Update Now**.

4. The update may restart the device including all services and packages once the update is complete.

## 9.2. Manually installing additional RAM in Synology DS920+

This runbook should be performed by the DevSecOps Engineer.

1. Before installing the RAM, perform any updates to the DSM first.

| The RAM used is the official Synology Memory Module, D4NESO-2666-4G, DDR4-2666 260pin, Non-ECC Unbuffered SO-DIMM 4GB RAM.

2. Check your existing memory size before shutting down your Synology NAS.

3. Remove all the HDD trays from your NAS while taking note of the order.

4. Earth yourself by touching a heavy metal object first.

5. Insert the additional RAM on the right inner wall of the NAS until you hear a click sound.

6. Insert all the HDD trays in the same order as before.

7. Start your Synology NAS and check your new memory size.

---
# 10. Troubleshooting
## 10.1 Using SSH connection type with passwords

If you get this error when using option ` -k` to ask for connection password, you must install the sshpass program.

```sh
<SERVER_IP> | FAILED! => {
    "msg": "to use the 'ssh' connection type with passwords, you must install the sshpass program"
}
```

> There are instructions on how to install **sshpass** here:
>
> https://gist.github.com/arunoda/7790979

For macOS, you will need to install **Xcode** and command line tools then use the unofficial Homebrew command:

```sh
brew install hudochenkov/sshpass/sshpass
```

## 10.2. Too many authentication failure

If you get the following SSH Error:

```sh
$ Received disconnect from host: 2: Too many authentication failures
```

This could happen if you have five or more DSA/RSA identity files stored in your .ssh directory. In this case if the -i option isn't specified at the command line the ssh client will first attempt to login using each identity (private key) and next prompt for password authentication. However, sshd drops the connection after five bad login attempts (again default may vary).

So if you have a number of private keys in your .ssh directory you could disable Public Key Authentication at the command line using the -o optional argument.

```sh
ssh -o PubkeyAuthentication=no <user>@<serverip>
```

---
## 10.3. You are still asked by SSH to enter a password

SSH to your server and change the following permissions:

```sh
chmod 755 $HOME
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

---
## 10.4. Missing sudo password

If you get the following error:

```sh
fatal: [192.168.86.32]: FAILED! => {"msg": "Missing sudo password"}
```

Connect to your Synology NAS via SSH and then become a superuser `sudo su -`. Enter your `root` password which should be the same as your `admin` password.

Create a file `/etc/sudoers.d/admin` and add the following line:

```
admin ALL=(ALL) NOPASSWD:ALL
```

You have enabled superuser for your Ansible commands.

---
## 10.5. Error Start container zt failed

> Note: Synology DSM 6 `root` account has been hardened. You can no longer SSH using `root`, however you can still `sudo -i` after logging in as any member account of the administrators group.

If you get the following error log in your Synology Docker:

```json
{"message":"error gathering device information while adding custom device \"/dev/net/tun\": no such file or directory"}
```

1. Create a file `/tun.sh` and type the following code:

```sh
#!/bin/sh

# Create the necessary file structure for /dev/net/tun
if ( [ ! -c /dev/net/tun ] ); then
  if ( [ ! -d /dev/net ] ); then
    mkdir -m 755 /dev/net
  fi
  mknod /dev/net/tun c 10 200
  chmod 0755 /dev/net/tun
fi

# Load the tun module if not already loaded
if ( !(lsmod | grep -q "^tun\s") ); then
  insmod /lib/modules/tun.ko
fi
```

2. Make the script executable with `chmod a+x /tun.sh`.

3. Make the script run on every restart.
  - Navigate to **Synology Control Panel > Task Scheduler**.
  - Click **Create > Triggered Task > User-defined script**.
  - Click on **General** tab.
    - For **User** select `admin`.
    - For **Event** select `Boot-up`.
    - Click on **Enabled** task.
  - Click on **Task Settings** tab.
    - For **Run command > User-defined script**, type:
      ```
      sudo bash /tun.sh
      echo $?
      ```
  - Click **OK**.

4. After restarting the `zt` container, check the node status:
  ```
  $ sudo docker exec -it zt zerotier-cli status
  200 info xxxxxx9857 1.8.10 ONLINE
  ```

---
# 11. References
The following resources were used as a single-use reference.

| Title | Author | Publisher Date [Short Code]
|---|---|---|
| [Discussion: Authelia - SSO & 2FA portal](https://www.synoforum.com/threads/authelia-sso-2fa-portal.5952/) | Rusty | May 2021
| [Authelia - SSO and 2FA portal](https://www.blackvoid.club/authelia-sso-and-2fa-portal/) | Luke Manestar | May 2021
| [NGINX proxy manager](https://www.blackvoid.club/nginx-proxy-manager/) | Luke Manestar | Apr 2021
| GitHub repo: [CLI client for Portainer](https://github.com/greenled/portainer-stack-utils) | Juan Carlos Mejías Rodríguez | Oct 2019
| Ansible for DevOps
| [How to build your inventory ](https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html) | Ansible Documentation | 2022
| [Synology Docker Media Server with Traefik, Docker Compose, and Cloudflare](https://www.smarthomebeginner.com/synology-docker-media-server) | Anand | Jul 2020
| [Prevent DSM Listening on Port 80/443](https://www.reddit.com/r/synology/comments/ahs3xh/prevent_dsm_listening_on_port_80443)
| [DSM broken after latest Update](https://community.synology.com/enu/forum/17/post/96886)
| [Prevent DSM Listening on Port 80/443](https://www.reddit.com/r/synology/comments/ahs3xh/prevent_dsm_listening_on_port_80443/)
| [Synology NAS | ZeroTier Documentation](https://docs.zerotier.com/devices/synology/)
| [Solved - --device /dev/net/tun not working anymore after Docker update 18.09.0-0513](https://www.synoforum.com/threads/device-dev-net-tun-not-working-anymore-after-docker-update-18-09-0-0513.3074/)
| [Fix TUN/TAP not available on a Synology NAS](https://memoryleak.dev/post/fix-tun-tap-not-available-on-a-synology-nas/)
