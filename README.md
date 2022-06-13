<h1> SecurityInDistributedSystems Notes </h1>

DockerFiles, Certificate chains, Apache Server, Basic Authentication...

- [1. certificates](#1-certificates)
  - [1.1. Tutorials](#11-tutorials)
  - [1.2. Random Notes](#12-random-notes)
  - [1.3. Professor notices](#13-professor-notices)
  - [1.4. Credentials](#14-credentials)
- [2. ssh](#2-ssh)
  - [2.1. ssh without password (using a public and a private key)](#21-ssh-without-password-using-a-public-and-a-private-key)
  - [2.2. setting up ssh tunneling to connect and send files to the server](#22-setting-up-ssh-tunneling-to-connect-and-send-files-to-the-server)
  - [2.3. Credentials](#23-credentials)
  - [2.4. Random Notes](#24-random-notes)
- [3. web server](#3-web-server)
  - [3.1. Link to server](#31-link-to-server)
    - [3.1.1. Check the Certificate Quality](#311-check-the-certificate-quality)
  - [3.2. Credentials](#32-credentials)
- [4. Docker](#4-docker)
  - [4.1. Commands](#41-commands)

## 1. certificates

### 1.1. Tutorials

- [PKI guide from prfessor](https://pki-tutorial.readthedocs.io/en/latest/#), It talks about the 3 layered structure in the [Advanced PKI Example](https://pki-tutorial.readthedocs.io/en/latest/advanced/index.html)
- <s>[Our Tutorial](https://www.golinuxcloud.com/openssl-create-certificate-chain-linux/#Root_vs_Intermediate_Certificate) (didn't end up working)</s>
- [JusT](https://github.com/JOSEALM3IDA)'s suggested [tutorial](https://superuser.com/questions/126121/how-to-create-my-own-certificate-chain)
- [Carol's](https://github.com/carolinafigueiredo1?tab=repositories) suggested [tutorial](https://pki-tutorial.readthedocs.io/en/latest/advanced/index.html) (the one that worked!)  
  1. Starting with just the conf files

        ```txt
        ├── etc
        │   ├── openssl_changed.conf
        │   ├── root-ca.conf
        │   ├── server.conf
        │   └── tls-ca.conf
        ```

  2. [Create Root CA](https://pki-tutorial.readthedocs.io/en/latest/advanced/index.html#create-root-ca)
  3. [Create TLS (intermidiate) CA](https://pki-tutorial.readthedocs.io/en/latest/advanced/index.html#create-tls-ca)
  4. [Create TLS server certificate](https://pki-tutorial.readthedocs.io/en/latest/advanced/index.html#operate-tls-ca) until ~6.3.
     1. This with all the infor for the haw server:

        ```conf
        ## TLS server Configuration File

        [ default ]
        SAN                     = DNS:ful.informatik.haw-hamburg.de

        [ req ]
        default_bits            = 2048
        encrypt_key             = no
        default_md              = sha256
        string_mask             = nombstr
        prompt                  = yes
        distinguished_name      = server_dn
        req_extensions          = server_reqext
        prompt = no

        [ server_dn ]
        countryName             = DE
        stateOrProvinceName     = Hamburg
        organizationName        = haw-hamburg
        organizationalUnitName  = SVS
        commonName              = svs24.ful.informatik.haw-hamburg.de

        [ server_reqext ]

        keyUsage                = critical,digitalSignature,keyEncipherment
        extendedKeyUsage        = serverAuth,clientAuth
        subjectKeyIdentifier    = hash
        subjectAltName          = $ENV::SAN

        ```

     2. notice how we also had to add `prompt = no` for it to work

### 1.2. Random Notes

- Letters meaning in creation of certificates:

  ```txt
    CN: CommonName  
    OU: OrganizationalUnit  
    O: Organization  
    L: Locality  
    S: StateOrProvinceName  
    C: CountryName 
  ```

### 1.3. Professor notices

- key size should be at least 4096
- being a certification authority : yes / no (yes for root certificate, yes for the 2nd certificate, no for the last one?)
- see the Universities certificate (in firefox click the lock in the site and view certificate in the new window
- CRLs endpoint of CA certificates (revocation links?) (you can use http://svsXX. as server for CRL)

### 1.4. Credentials

- Our certificates passphrase: *Stunt-Headwear-Lung1*

## 2. ssh

### 2.1. ssh without password (using a public and a private key)

- Watch [this](https://www.youtube.com/watch?v=lKXMyln_5q4)

### 2.2. setting up [ssh tunneling](https://superuser.com/questions/456438/how-do-i-scp-a-file-through-an-intermediate-server) to connect and send files to the server

- add this to your ~/.ssh/config file:

  ```txt
      Host haw
      User          otto
      HostName      svs24.ful.informatik.haw-hamburg.de
      ProxyCommand  ssh Joao.SilvadeAlmeida@haw-hamburg.de@hop-ful.informatik.haw-hamburg.de  nc %h %p 2> /dev/null
  ```

- You can then ssh with `ssh haw`
- Or copy files to there with: `scp ./folderName.tgz haw:~`

### 2.3. Credentials

- When doing `ssh haw`:
  - First input your password for your haw account
  - Input the machine's password: *Tierlieb* *(should change)*

### 2.4. Random Notes

- If you wanted to login without typing a password, you had to put the public key of your computer on the remote servers, and do ssh tunneling somehow.
- Go to the server and in a .ssh put my public key from your PC..?

## 3. web server

- apache:
  - configuration at `DockerBlueprintApacheServ/apache2-user-config.conf`  
  or inside container: `/etc/apache2/sites-available/webportal.conf`
  - html at `DockerBlueprintApacheServ/userdata/webportal/index.html`  
  or inside container: `/userdata/webportal/index.html`

### 3.1. [Link to server](https://svs24.ful.informatik.haw-hamburg.de/)

#### 3.1.1. [Check the Certificate Quality](https://www.ssllabs.com/ssltest/analyze.html?d=svs24.ful.informatik.haw%2dhamburg.de&latest)

### 3.2. Credentials

- Basic Authentication, used [this](https://www.youtube.com/watch?v=00bwCjPp-FU&ab_channel=TonyTeachesTech) to setup
  - User: admin
  - Paswword: Stunt-Headwear-Lung1

## 4. Docker

### 4.1. Commands

- switch to inside running docker image: `docker exec -t -i svs /bin/bash`
- Command to delete everything and restart everything:

  ```bash
  docker rm -vf $(docker ps -aq) ; docker rmi -f $(docker images -aq) ; docker build -t svs:latest . ; docker run -d -p 80:80 -p 443:443 --name svs svs:latest
  ```
