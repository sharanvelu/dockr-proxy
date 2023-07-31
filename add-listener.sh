#!/bin/bash

## DockR by Sharan

INCOMING_DOMAIN=$1
PROXY_SITE=$2
PROXY_APP_PORT=$3
PROXY_VITE_PORT=$4

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

    client_max_body_size 1000M;

    location / {
        # Pass the request to the specified Site via Proxy
        proxy_pass ${PROXY_SITE}:${PROXY_APP_PORT};
        proxy_set_header Host \$host;

        # Additional Headers
        proxy_set_header X-Real-IP  \$remote_addr;
        proxy_set_header X-Forwarded-For \$remote_addr;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}

server {
    listen 5173;

    # Listen for specified Domain Name
    server_name ${INCOMING_DOMAIN};

    client_max_body_size 1000M;

    location / {
        # Pass the request to the specified Site via Proxy
        proxy_pass ${PROXY_SITE}:${PROXY_VITE_PORT};
        proxy_set_header Host \$host;

        # Additional Headers
        proxy_set_header X-Real-IP  \$remote_addr;
        proxy_set_header X-Forwarded-For \$remote_addr;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}"

# Generate certificate for the specified domain
generate_certificate() {
    # Make new directory for domain certificate if the dir doesn't exist
    if [ ! -d "${DT_CERTIFICATE_PATH}" ]; then
        mkdir -p ${DT_CERTIFICATE_PATH}

        # Create self signing SSL certificate if it doesn't exist
        if [ ! -f "${DT_CERTIFICATE_PATH}/key.key" ]; then
            openssl req -x509 -nodes \
                -days 365 \
                -subj "/C=IN/ST=TN/O=DockR/OU=IT/CN=${INCOMING_DOMAIN}/MAIL=admin@${INCOMING_DOMAIN}" \
                -addext "subjectAltName=DNS:${INCOMING_DOMAIN}" \
                -newkey rsa:2048 \
                -keyout ${DT_CERTIFICATE_PATH}/key.key \
                -out ${DT_CERTIFICATE_PATH}/cert.crt >> /dev/null 2>&1;
        fi
    fi
}

# Adds the Proxy Listener for specified Domain
add_listener() {
    generate_certificate

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

sleep 2
