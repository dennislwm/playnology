# Deprecated

---
# 2. System Overview

## 2.3. Security

### Tailscale

* Device Approval: requires new devices to be approved before they can access the network.
* Key Expiry: set the number of days (1-180) a device can stay logged in to Tailscale before it needs to reauthenticate.
* User Approval: requires new users to be approved before they can access the network.

---
# 3. User Personas
## 3.1 RACI Matrix

|           Category           |                           Activity                            | Mobile User | DSO Engineer |
|:----------------------------:|:-------------------------------------------------------------:|:-----------:|:------------:|
| Installation & Configuration |          [Setting up LDAP on your Synology NAS][i02]          |             |     R,A      |
| Installation & Configuration |   [Setting up `configuration.yml` for Authelia stack][i03]    |             |     R,A      |
| Installation & Configuration |      [Install and configure ZeroTier One on iPhone][i06]      |     R,A     |      C       |
|          Execution           | [Access and bookmark container apps from NAS on iPhone][e08]  |     R,A     |              |
|       Troubleshooting        |            [Error Start container zt failed][t01]             |      I      |     R,A      |

[i02]: #52-setting-up-ldap-on-your-synology-nas
[i03]: #53-setting-up-configurationyml-for-authelia-stack
[i06]: #56-install-and-configure-zerotier-one-on-iphone
[e08]: #68-access-and-bookmark-container-apps-from-nas-on-iphone
[t01]: #105-error-start-container-zt-failed

---
# 4. Requirements
## 4.1. Synology
### 4.1.4. Adding Docker container

There are two methods to pull a new Docker image and add a running container:

1. Using Docker Compose
2. Using Portainer

#### Using Docker Compose (Deprecated)
<details><summary>Click here to Using Docker Compose (Deprecated).</summary><br>

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
</details>

### 4.1.5. Prevent Synology Listening on Port 80/443 (Deprecated)
<details><summary>Click here to Prevent Synology Listening on Port 80/443 (Deprecated).</summary><br>

Synology DSM is configured to run on both default ports 5000 and 5001. However, it's listening on ports 80 and 443 for redirection.

In order to free ports 80 and 443, we will replace these ports with 82 and 444, respectively.

```bash
sudo sed -i -e 's/80/82/' -e 's/443/444/' /usr/syno/share/nginx/server.mustache /usr/syno/share/nginx/DSM.mustache /usr/syno/share/nginx/WWWService.mustache
sudo synoservicecfg --restart nginx
```
</details>

### 4.1.6. Dangerous (Deprecated)
<details><summary>Click here to Dangerous (Deprecated).</summary><br>

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
</details>

## 4.2. ZeroTier One
<details><summary>Click here to ZeroTier One.</summary><br>

### iPhone

[Download on the App Store](https://www.zerotier.com/download/)
</details>

## 4.3. Tailscale
<details><summary>Click here to Tailscale.</summary><br>

### SaaS

* [Create a Tailscale account](https://tailscale.com)
  * Free tier (Personal) account has up to 3 users with public domain and up to 100 devices.
    * SSO with any IdP
    * User Approval
    * Network, Resource-level, and Attribute-based ACLs
    * MagicDNS
    * Peer-to-Peer Connections
  * Todos:
    * Set up DNS: Tailscale gives devices `100.x.y.z` IP addresses, but you can also set up DNS to more easily connect to your devices.
    * Share a node: Sharing lets you give a Tailscale user on another network access to a device within your network, without exposing it publicly.
    * Set up access controls: By default, every device can talk to every device. You can define rules to limit which devices can talk to each other.
    * Set up Taildrop: Taildrop lets you send files between your personal devices on a Tailscale network (known as a tailnet).

### iPhone

* [Download on the App Store](https://apps.apple.com/us/app/tailscale/id1470499037?ls=1)

### macOS

* [Download on the Mac App Store](https://apps.apple.com/ca/app/tailscale/id1475387142?mt=12)

### Synology

* [Download from Synology Package Center](https://tailscale.com/kb/1131/synology#install-using-synology-package-center)
</details>

---
# 5. Installation and Configuration

## 5.2. Setting up LDAP on your Synology NAS
<details><summary>Click here to Setting up LDAP on your Synology NAS.</summary><br>

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
</details>

## 5.6. Install and configure ZeroTier One on iPhone
<details><summary>Click here to Install and configure ZeroTier One on iPhone.</summary><br>

This runbook should be performed by the Mobile User.

1. Download and install the **ZeroTier One** app.

2. Open the app and click `+`.

3. Enter the **Network ID** from your ZeroTier account.
  - Enable Default Route.
  - Enable On Demand (beta).

4. Click on **Add Network**.
  - Check that the Status is `OK`.
</details>

## 5.3. Setting up `configuration.yml` for Authelia stack

This runbook should be performed by the DevSecOps.
<details><summary>Click here to Setting up `configuration.yml` for Authelia stack.</summary><br>

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
</details>

---
# 6. Execution
## 6.8. Access and bookmark container apps from NAS on iPhone
<details><summary>Click here to Access and bookmark container apps from NAS on iPhone.</summary><br>

This runbook should be performed by the Mobile User.

1. On your iPhone, open a browser and type the URL as follows:
  - `ZEROTIER_MANAGED_IP:NAS_PORT`, e.g. `172.29.xxx.xxx:8100`

| Note: Accessing the container app requires both **ZeroTier One** running on your iPhone and NAS.

2. You should see the home page of your container app.

3. Bookmark the page on your browser.
</details>

---
# 10. Troubleshooting
## 10.5. Error Start container zt failed

<details><summary>Click here to troubleshoot Error Start container zt failed.</summary><br>

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
</details>

---
# 11. References
The following resources were used as a single-use reference.

| Title                                                                                      | Author                       | Publisher Date [Short Code] |
|--------------------------------------------------------------------------------------------|------------------------------|-----------------------------|
| [Discussion: Authelia - SSO & 2FA portal][r01]                                             | Rusty                        | May 2021                    |
| [Authelia - SSO and 2FA portal][r02]                                                       | Luke Manestar                | May 2021                    |
| [NGINX proxy manager][r03]                                                                 | Luke Manestar                | Apr 2021                    |
| [Prevent DSM Listening on Port 80/443][r07]                                                |                              |                             |
| [Synology NAS - ZeroTier Documentation][r10]                                               |                              |                             |
| [Solved - --device /dev/net/tun not working anymore after Docker update 18.09.0-0513][r11] |                              |                             |
| [Fix TUN/TAP not available on a Synology NAS][r12]                                         |                              |                             |

[r01]: https://www.synoforum.com/threads/authelia-sso-2fa-portal.5952/
[r02]: https://www.blackvoid.club/authelia-sso-and-2fa-portal/
[r03]: https://www.blackvoid.club/nginx-proxy-manager/
[r07]: https://www.reddit.com/r/synology/comments/ahs3xh/prevent_dsm_listening_on_port_80443
[r10]: https://docs.zerotier.com/devices/synology/
[r11]: https://www.synoforum.com/threads/device-dev-net-tun-not-working-anymore-after-docker-update-18-09-0-0513.3074/
[r12]: https://memoryleak.dev/post/fix-tun-tap-not-available-on-a-synology-nas/
