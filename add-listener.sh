#!/bin/bash

## DockR by Sharan

INCOMING_DOMAIN=$1
PROXY_SITE=$2

LISTEN_80="server {
    listen 80;
    server_name ${INCOMING_DOMAIN};
    location / {
        proxy_pass ${PROXY_SITE};
        proxy_set_header Host \$host;
    }
}"

LISTEN_443="server {
    listen 443;
    server_name ${INCOMING_DOMAIN};
    location / {
        proxy_pass ${PROXY_SITE};
        proxy_set_header Host \$host;
        proxy_set_header Scheme http;
    }
}"

add_listener() {
    echo "${LISTEN_80}" >> /etc/nginx/sites-available/${INCOMING_DOMAIN}

    ln -s /etc/nginx/sites-available/${INCOMING_DOMAIN} /etc/nginx/sites-enabled/${INCOMING_DOMAIN}
}

remove_existing_listener() {
    rm -rf /etc/nginx/sites-enabled/${INCOMING_DOMAIN}
    rm -rf /etc/nginx/sites-available/${INCOMING_DOMAIN}
}

remove_existing_listener

add_listener

service nginx reload
