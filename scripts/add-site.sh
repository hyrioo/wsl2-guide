#!/bin/bash -e

BASEDIR=$(dirname $0)
PORT=${2-80}

# Create v3.ext file with domains
IFS=',' read -r -a INITIAL_DOMAINS <<< "$1"

DOMAINS=()
MAIN_DOMAIN=$INITIAL_DOMAINS
for DOMAIN in "${INITIAL_DOMAINS[@]}"
do
        DOMAINS+=($DOMAIN)
        DOMAINS+=("*.$DOMAIN")
done
SERVER_NAME="${DOMAINS[*]}"

IFS=','
${BASEDIR}/generate-ssl.sh "${DOMAINS[*]}"

cat <<EOF >/etc/nginx/sites-available/$MAIN_DOMAIN.conf
server {
        listen 80;
        server_name ${SERVER_NAME};

        location / {
                proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;
                proxy_set_header   X-Forwarded-Host \$host;
                proxy_set_header   X-FORWARDED-PROTO http;
                proxy_pass http://localhost:${PORT};
        }
}
server {
        listen 443 http2 ssl;
        server_name ${SERVER_NAME};

        ssl_certificate     /etc/ssl/certs/sites/${MAIN_DOMAIN}/ssl.crt;
        ssl_certificate_key /etc/ssl/certs/sites/${MAIN_DOMAIN}/ssl.key;

        ssl_session_cache  builtin:1000  shared:SSL:10m;
        ssl_protocols  TLSv1 TLSv1.1 TLSv1.2;
        ssl_ciphers HIGH:!aNULL:!eNULL:!EXPORT:!CAMELLIA:!DES:!MD5:!PSK:!RC4;
        ssl_prefer_server_ciphers on;

        location / {
                proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;
                proxy_set_header   X-Forwarded-Host \$host;
                proxy_set_header   X-FORWARDED-PROTO https;
                proxy_pass http://localhost:${PORT};
        }
}
EOF

if [ ! -f /etc/nginx/sites-enabled/$MAIN_DOMAIN.conf ]; then
        ln -s /etc/nginx/sites-available/$MAIN_DOMAIN.conf /etc/nginx/sites-enabled
fi
service nginx reload
echo "Site added to nginx"