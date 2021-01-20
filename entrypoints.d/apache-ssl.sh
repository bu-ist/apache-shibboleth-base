#!/bin/bash

# Generate self-signed SSL certificate, for use with frontend-to-backend communications:
set -x
openssl req -x509 -newkey rsa:4096 -keyout /etc/pki/tls/private/localhost.key -out /etc/pki/tls/certs/localhost.cert -days 365 -nodes -subj "/C=US/ST=Massachusetts/L=Boston/O=Boston University/"
set +x
