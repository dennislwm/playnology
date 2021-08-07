# playnology

Ansible starter project for your Synology NAS.

- [playnology](#playnology)
  - [Installing Ansible](#installing-ansible)
  - [Creating a basic inventory file](#creating-a-basic-inventory-file)
  - [Running your first Ad-Hoc Ansible command](#running-your-first-ad-hoc-ansible-command)
  - [Your first Ansible playbook](#your-first-ansible-playbook)
  - [Troubleshooting](#troubleshooting)
    - [Using SSH connection type with passwords](#using-ssh-connection-type-with-passwords)
    - [Too many authentication failure](#too-many-authentication-failure)
    - [You are still asked by SSH to enter a password](#you-are-still-asked-by-ssh-to-enter-a-password)
    - [Missing sudo password](#missing-sudo-password)
  - [References](#references)

# Installing Ansible

**Ansible**'s only real dependency is Python. Once Python is installed, the simplest way to get Ansible running is to use `pip`.

```
pip install ansible
```

> You must enable SSH remote connection on your Synology NAS before running Ansible commands. You can follow the steps in this article:
> 
> [Configure the SSH server on your Synology NAS](https://flatpacklinux.com/2020/01/07/configure-the-ssh-server-on-your-synology-nas)

# Creating a basic inventory file

Ansible uses an inventory file (basically, a list of servers) to communicate with your servers. Create a file `hosts` in your project root folder and add one server to it:

```yml
[wifi]
192.0.2.5
```

The `wifi` is an arbitrary name for the group of servers you're managing, followed by the IP addresses of your servers, one per line. If you're not using port 22 for SSH, you will need to append it to the address.

# Running your first Ad-Hoc Ansible command

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

# Your first Ansible playbook

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

# Troubleshooting

## Using SSH connection type with passwords

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

## Too many authentication failure

If you get the following SSH Error:

```sh
$ Received disconnect from host: 2: Too many authentication failures
```

This could happen if you have five or more DSA/RSA identity files stored in your .ssh directory. In this case if the -i option isn't specified at the command line the ssh client will first attempt to login using each identity (private key) and next prompt for password authentication. However, sshd drops the connection after five bad login attempts (again default may vary).

So if you have a number of private keys in your .ssh directory you could disable Public Key Authentication at the command line using the -o optional argument.

```sh
ssh -o PubkeyAuthentication=no <user>@<serverip>
```

## You are still asked by SSH to enter a password

SSH to your server and change the following permissions:

```sh
chmod 755 $HOME
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

## Missing sudo password 

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

# Synology

## Changing SSH Password

### Enabling SSH

You can enable SSH service from the `Control Panel`. Go to `Terminal & SNMP` and check the box `Enable SSH service` and click `Apply`.

After enabling SSH service, you will find out that you are unable to login with the admin password on the Synology web interface. We will need to temporarily enable Telnet service to fix this problem.

### Temporarily Enabling Telnet

Under the previous `Terminal & SNMP`, check the box `Enable Telnet service` and click `Apply`. You have to connect to both Telnet and SSH on the LAN because it doesn't work with Quickconnect.

On your iPhone, download the app iTerminal. Open the app and create a Telnet connection specifying your `[PRIVATE_IP]` address on port `23`.

Login using `admin` and same password as your Synology web interface. Type the following command to change the SSH password:

```bash
$ sudo synouser --setpw admin [PASSWORD]
```

If it doesn't work the first time, try again. After changing the password, you should be able to SSH to your Synology.

Return to your Synology `Control Panel`, and disable the Telnet service. 

*Warning: Changing the `admin` password using Task Scheduler did not work.*

## Connecting via SSH

Using the app iTerminal, create an SSH connection specifying your IP address on port 22. Login using admin and your password, and type EXACT:

```bash
$ sudo ln -s /var/run/docker.sock /volume1/docker/docker.sock
```

*Warning: Even after creating the symlink you cannot create the container from the Docker UI. This is because symlinks are not listed when trying to create a volume/file link.*

## Installing Portainer

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

## Adding Docker container

There are two methods to pull a new Docker image and add a running container:

1. Using Docker Compose
2. Using Portainer

### Using Docker Compose

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

### Prevent Synology Listening on Port 80/443

Synology Disk Station Manager ["DSM"] is configured to run on both default ports 5000 and 5001. However, it's listening on ports 80 and 443 for redirection.

In order to free ports 80 and 443, we will replace these ports with 82 and 444, respectively. 

```bash
sudo sed -i -e 's/80/82/' -e 's/443/444/' /usr/syno/share/nginx/server.mustache /usr/syno/share/nginx/DSM.mustache /usr/syno/share/nginx/WWWService.mustache
sudo synoservicecfg --restart nginx
```

### Dangerous

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

### Using Portainer

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

## NGINX Proxy Manager

### Enabling Port Forwarding on Router

You may need to enable port forwarding on both your Google Home WiFi and router.

# References

* Ansible for DevOps

* [How to build your inventory — Ansible Documentation](https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html)

* [Setup and install Portainer on Synology NAS](https://nashosted.com/setup-and-install-portainer-on-synology-nas) 

* [Synology Docker Media Server with Traefik, Docker Compose, and Cloudflare](https://www.smarthomebeginner.com/synology-docker-media-server)

# Troubleshooting

* [Prevent DSM Listening on Port 80/443](https://www.reddit.com/r/synology/comments/ahs3xh/prevent_dsm_listening_on_port_80443)

* [DSM broken after latest Update](https://community.synology.com/enu/forum/17/post/96886)
