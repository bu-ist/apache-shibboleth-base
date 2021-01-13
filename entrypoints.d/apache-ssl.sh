#!/bin/bash

# Generate self-signed SSL certificate, for use with frontend-to-backend communications:
set -x
mkdir -p /etc/ssl/apache
cd /etc/ssl/apache
openssl req -x509 -newkey rsa:4096 -keyout cert.key -out cert.pem -days 365 -nodes -subj "/C=US/ST=Massachusetts/L=Boston/O=Boston University/"
set +x
ls -l /etc/ssl/apache
