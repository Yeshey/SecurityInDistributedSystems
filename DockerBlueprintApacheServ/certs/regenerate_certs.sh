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
    -caname "Green TLS CA" \
    -caname "Green Root CA" \
    -inkey certs/$COMMONNAME.key \
    -in certs/$COMMONNAME.crt \
    -certfile ca/tls-ca-chain.pem \
    -out certs/$COMMONNAME.p12

: '

echo "6.4 Creating TLS client request"
openssl req -new \
    -config etc/client.conf \
    -out certs/barney.csr \
    -keyout certs/barney.key

echo "6.5 Create TLS client certificate"
openssl ca \
    -config etc/tls-ca.conf \
    -in certs/barney.csr \
    -out certs/barney.crt \
    -policy extern_pol \
    -extensions client_ext

echo "6.6 Creating PKCS#12 bundle"
openssl pkcs12 -export \
    -name "Barney Rubble (Network Access)" \
    -caname "Green TLS CA" \
    -caname "Green Root CA" \
    -inkey certs/barney.key \
    -in certs/barney.crt \
    -certfile ca/tls-ca-chain.pem \
    -out certs/barney.p12

echo "6.7 Revoke certificate"
openssl ca \
    -config etc/tls-ca.conf \
    -revoke ca/tls-ca/02.pem \
    -crl_reason affiliationChanged

echo "6.8 Creating CRL"
openssl ca -gencrl \
    -config etc/tls-ca.conf \
    -out crl/tls-ca.crl

'

echo "Creating CA-bundle file from CRT files"
# https://cleantalk.org/help/ssl-ca-bundle
cat ./ca/root-ca.crt ./ca/tls-ca.crt > ./ca/svs24.ca-bundle