#!/bin/bash -e

BASEDIR=$(dirname $0)
DOMAINS=$1

# Create v3.ext file with domains
cp -fr ${BASEDIR}/v3.ext ${BASEDIR}/v3.ext.tmp
IFS=',' read -r -a array <<< "$DOMAINS"
I=1
DOMAIN=$array
for element in "${array[@]}"
do
    echo -e "DNS.$I = $element" >> ${BASEDIR}/v3.ext.tmp
    I=$((I+1))
done

ROOT_DIR=/etc/ssl/certs
ROOT_NAME="HyriooRoot.rca"
CERT_DIR=/etc/ssl/certs/sites/${DOMAIN}
CERT_NAME="ssl"
COMPANY="Hyrioo"
CITY="Vejle"
COUNTRY="DK"

echo "Generate SSL certificate for $DOMAINS"

mkdir -p $CERT_DIR

# Generate the root CA if it doesn't exist
if [ ! -f ${ROOT_DIR}/${ROOT_NAME}.crt ]; then
        echo "Generate new root certificate authority"
        (openssl genrsa -out ${ROOT_DIR}/${ROOT_NAME}.key 2048) 2>/dev/null
        (openssl req -x509 -new -nodes -key ${ROOT_DIR}/${ROOT_NAME}.key -sha256 -days 1095 -subj "/C=$COUNTRY/L=$CITY/O=$COMPANY" -out ${ROOT_DIR}/${ROOT_NAME}.crt) 2>/dev/null
fi


# Create a new private key if one doesnt exist, or use the existing one if it does
if [ -f ${CERT_DIR}/${CERT_NAME}.key ]; then
        echo "Using existing private key"
        KEY_OPT="-key"
else
        echo "Generating new private key"
        KEY_OPT="-keyout"
fi

# Generate certificate
SUBJECT="/C=$COUNTRY/L=$CITY/O=$COMPANY/CN=$DOMAIN"
NUM_OF_DAYS=1095
(openssl req -new -newkey rsa:2048 -sha256 -nodes $KEY_OPT ${CERT_DIR}/${CERT_NAME}.key -subj "$SUBJECT" -out ${CERT_DIR}/${CERT_NAME}.csr) 2>/dev/null
(openssl x509 -req -in ${CERT_DIR}/${CERT_NAME}.csr -CA ${ROOT_DIR}/${ROOT_NAME}.crt -CAkey ${ROOT_DIR}/${ROOT_NAME}.key -CAcreateserial -out ${CERT_DIR}/${CERT_NAME}.crt -days $NUM_OF_DAYS -sha256 -extfile ${BASEDIR}/v3.ext.tmp) 2>/dev/null
echo "Certificate generated successfully"
rm ${BASEDIR}/v3.ext.tmp