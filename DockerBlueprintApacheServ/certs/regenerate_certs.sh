#!/bin/bash

echo "Regenerating Certificates based on configuration..."

echo "Removing Previous Certificates..."
rm -r ca
rm -r certs
rm -r crl

echo "1. Creating Root Certificate"
# https://pki-tutorial.readthedocs.io/en/latest/advanced/index.html#create-root-ca

echo "1.1 Creating directories"
mkdir -p ca/root-ca/private ca/root-ca/db crl certs
chmod 700 ca/root-ca/private

echo "1.2 Creating database"
cp /dev/null ca/root-ca/db/root-ca.db
cp /dev/null ca/root-ca/db/root-ca.db.attr
echo 01 > ca/root-ca/db/root-ca.crt.srl
echo 01 > ca/root-ca/db/root-ca.crl.srl

echo "1.3 Creating CA request"
openssl req -new \
    -config etc/root-ca.conf \
    -out ca/root-ca.csr \
    -keyout ca/root-ca/private/root-ca.key

echo "1.4 Creating CA certificate"
openssl ca -selfsign \
    -config etc/root-ca.conf \
    -in ca/root-ca.csr \
    -out ca/root-ca.crt \
    -extensions root_ca_ext \
    -enddate 20301231235959Z

echo "1.5 Creating initial CRL"
openssl ca -gencrl \
    -config etc/root-ca.conf \
    -out crl/root-ca.crl

echo "3. Creating TLS (intermidiate) Certificate"
# https://pki-tutorial.readthedocs.io/en/latest/advanced/index.html#create-tls-ca

echo "3.1 Creating directories"
mkdir -p ca/tls-ca/private ca/tls-ca/db crl certs
chmod 700 ca/tls-ca/private

echo "3.2 Creating database"
cp /dev/null ca/tls-ca/db/tls-ca.db
cp /dev/null ca/tls-ca/db/tls-ca.db.attr
echo 01 > ca/tls-ca/db/tls-ca.crt.srl
echo 01 > ca/tls-ca/db/tls-ca.crl.srl

echo "3.3 Creating CA request"
openssl req -new \
    -config etc/tls-ca.conf \
    -out ca/tls-ca.csr \
    -keyout ca/tls-ca/private/tls-ca.key

echo "3.4 Creating CA certificate"
openssl ca \
    -config etc/root-ca.conf \
    -in ca/tls-ca.csr \
    -out ca/tls-ca.crt \
    -extensions signing_ca_ext

echo "3.5 Creating initial CRL"
openssl ca -gencrl \
    -config etc/tls-ca.conf \
    -out crl/tls-ca.crl

echo "3.6 Creating PEM bundle"
cat ca/tls-ca.crt ca/root-ca.crt > \
    ca/tls-ca-chain.pem

echo "6. Creating TLS server Certificate"
# https://pki-tutorial.readthedocs.io/en/latest/advanced/index.html#operate-tls-ca

COMMONNAME="svs24.ful.informatik.haw-hamburg.de"

echo "6.1 Creating TLS server request"
SAN=DNS:$COMMONNAME,DNS:www.$COMMONNAME \
openssl req -new \
    -config etc/server.conf \
    -out certs/$COMMONNAME.csr \
    -keyout certs/$COMMONNAME.key

echo "6.2 Creating TLS server certificate"
openssl ca \
    -config etc/tls-ca.conf \
    -in certs/$COMMONNAME.csr \
    -out certs/$COMMONNAME.crt \
    -extensions server_ext

echo "6.3 Creating PKCS#12 bundle"
openssl pkcs12 -export \
    -name "$COMMONNAME (Network Component)" \
    -caname "Haw TLS CA" \
    -caname "Haw Root CA" \
    -inkey certs/$COMMONNAME.key \
    -in certs/$COMMONNAME.crt \
    -certfile ca/tls-ca-chain.pem \
    -out certs/$COMMONNAME.p12

echo " A. Creating Intermidiate team certificate for user certificates"
echo "A.1 Creating directories"
mkdir -p ca/team-ca/private ca/team-ca/db crl certs
chmod 700 ca/team-ca/private

echo "A.2 Creating database"
cp /dev/null ca/team-ca/db/team-ca.db
cp /dev/null ca/team-ca/db/team-ca.db.attr
echo 01 > ca/team-ca/db/team-ca.crt.srl
echo 01 > ca/team-ca/db/team-ca.crl.srl

echo "A.3 Creating CA request"
openssl req -new \
    -config etc/team24-ca.conf \
    -out ca/team-ca.csr \
    -keyout ca/team-ca/private/team-ca.key

echo "A.4 Creating CA certificate"
openssl ca \
    -config etc/root-ca.conf \
    -in ca/team-ca.csr \
    -out ca/team-ca.crt \
    -extensions signing_ca_ext

echo "A.5 Creating initial CRL"
openssl ca -gencrl \
    -config etc/team24-ca.conf \
    -out crl/team-ca.crl

echo "A.6 Creating PEM bundle"
cat ca/team-ca.crt ca/root-ca.crt > \
    ca/team-ca-chain.pem

echo "7. Creating user certificates"
# https://pki-tutorial.readthedocs.io/en/latest/advanced/index.html#create-tls-client-request

echo "7.1. User Jonnas"
mkdir giveToJonnas

echo "6.4 Creating TLS client request"
openssl req -new \
    -config etc/client.conf \
    -out certs/jonnas.csr \
    -keyout certs/jonnas.key

echo "6.5 Creating TLS client certificate"
openssl ca \
    -config etc/team24-ca.conf \
    -in certs/jonnas.csr \
    -out certs/jonnas.crt \
    -extensions client_ext

echo "7.1.1 Converting jonnas certificate + key to pfx"
openssl pkcs12 -export -out giveToJonnas/jonnas.pfx -inkey certs/jonnas.key -in certs/jonnas.crt

echo "7.1.2 Making jonnas certificate chain"
cat certs/jonnas.crt ./ca/team-ca.crt ./ca/root-ca.crt > ./giveToJonnas/jonnas.ca-bundle

echo "7.1.3 Converting jonnas certificate chain to p7b (for Windows Microsoft)"
openssl crl2pkcs7 -nocrl -certfile ./giveToJonnas/jonnas.ca-bundle -out ./giveToJonnas/jonnas.p7b

echo "7.1.4 Jonnas also wants crt t make work in linux"
cp  ./ca/root-ca.crt ./giveToJonnas
cp  ./ca/team-ca.crt ./giveToJonnas
cp  ./certs/jonnas.crt ./giveToJonnas

echo "7.2. User Asguer"
mkdir giveToAsguer

echo "7.2.1 Creating TLS client request"
openssl req -new \
    -config etc/client.conf \
    -out certs/asguer.csr \
    -keyout certs/asguer.key

echo "7.2.2 Creating TLS client certificate"
openssl ca \
    -config etc/team24-ca.conf \
    -in certs/asguer.csr \
    -out certs/asguer.crt \
    -extensions client_ext

echo "7.2.1 Converting asguer certificate + key to pfx"
openssl pkcs12 -export -out giveToAsguer/asguer.pfx -inkey certs/asguer.key -in certs/asguer.crt

echo "7.2.2 Making asguer certificate chain"
cat certs/asguer.crt ./ca/team-ca.crt ./ca/root-ca.crt > ./giveToAsguer/asguer.ca-bundle

echo "7.2.3 Converting asguer certificate chain to p7b (for Windows Microsoft)"
openssl crl2pkcs7 -nocrl -certfile ./giveToAsguer/asguer.ca-bundle -out ./giveToAsguer/asguer.p7b

# in the users computer run the following commands to retrieve these files:
# scp -r svs24:/home/otto/SecurityInDistributedSystemsRepo/DockerBlueprintApacheServ/certs/giveToJonnas /mnt/DataDisk/Downloads/certs/

echo "Creating CA-bundle file from CRT files"
# https://cleantalk.org/help/ssl-ca-bundle
# Use one chain for server certificate
cat ./certs/svs24.ful.informatik.haw-hamburg.de.crt ./ca/tls-ca.crt ./ca/root-ca.crt > ./ca/svs24.ca-bundle
# Use another chain for user certificates
cat ./ca/team-ca.crt ./ca/root-ca.crt > ./ca/users.ca-bundle