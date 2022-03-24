#!/bin/bash

## DockR by Sharan

INCOMING_DOMAIN=$1
PROXY_SITE=$2

# Certificate path for the Specified Domain
DT_CERTIFICATE_PATH="/etc/ssl/${INCOMING_DOMAIN}"

# Configuration file content
LISTEN_CONF="server {
    listen 80;

    # SSL configuration
    listen 443 ssl http2;
    ssl_certificate ${DT_CERTIFICATE_PATH}/cert.crt;
    ssl_certificate_key ${DT_CERTIFICATE_PATH}/key.key;

    # Listen for specified Domain Name
    server_name ${INCOMING_DOMAIN};
    location / {
        # Pass the request to the specified Site via Proxy
        proxy_pass ${PROXY_SITE};
        proxy_set_header Host \$host;

        # Additional Headers
        proxy_set_header X-Real-IP  \$remote_addr;
        proxy_set_header X-Forwarded-For \$remote_addr;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}"

# Adds the Proxy Listener for specified Domain
add_listener() {
    # Make new directory for domain
    mkdir ${DT_CERTIFICATE_PATH}

    # Create self signing SSL certificate
    openssl req -x509 -nodes \
        -days 365 \
        -subj "/C=IN/ST=TN/O=DockR/CN=${INCOMING_DOMAIN}" \
        -addext "subjectAltName=DNS:${INCOMING_DOMAIN}" \
        -newkey rsa:2048 \
        -keyout ${DT_CERTIFICATE_PATH}/key.key \
        -out ${DT_CERTIFICATE_PATH}/cert.crt >> /dev/null 2>&1;

    # Create Configuration file for Specified Domain
    echo "${LISTEN_CONF}" >> /etc/nginx/sites-available/${INCOMING_DOMAIN}

    # Create a link for enabling the created conf.
    ln -s /etc/nginx/sites-available/${INCOMING_DOMAIN} /etc/nginx/sites-enabled/${INCOMING_DOMAIN}
}

# Remove the Proxy for specified Domain
remove_existing_listener() {
    rm -rf /etc/nginx/sites-enabled/${INCOMING_DOMAIN}
    rm -rf /etc/nginx/sites-available/${INCOMING_DOMAIN}
}

remove_existing_listener

add_listener

service nginx reload
