#!/bin/bash

SSL_CERTIFICATE_KEY="/etc/ssl/le/live/$ROOT_SERVER_NAME/privkey.pem"
SSL_CERTIFICATE="/etc/ssl/le/live/$ROOT_SERVER_NAME/fullchain.pem"
CA_CERTIFICATE="/nginx/config/ca/cacert.pem"

HEADER="
user nginx;\n
worker_processes 1;\n
load_module \"modules/ngx_stream_module.so\";\n

error_log /dev/stdout;\n

events {\n
    worker_connections 1024;\n
}\n

http {\n
    server_names_hash_bucket_size   64;\n
    server_tokens                   off;\n
    sendfile                        off;\n
    client_max_body_size 10M;\n
    default_type application/octet-stream;\n
    proxy_buffering off;\n
    reset_timedout_connection on;\n
    access_log off;\n

    ssl_certificate $SSL_CERTIFICATE;\n
    ssl_certificate_key $SSL_CERTIFICATE_KEY;\n
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;\n
    ssl_ciphers HIGH:!aNULL:!MD5;\n

    server {\n
        listen 80;\n
        server_name $SERVER_NAME;\n
        return 301 https://\$host\$request_uri;\n
    }\n

    server {\n
        listen 443 ssl;\n
        server_name $SERVER_NAME;\n

        location / {\n
            proxy_pass http://$BOT_CONTAINER;\n
        }\n
    }\n
}\n\n
stream {\n
    ssl_certificate $SSL_CERTIFICATE;\n
    ssl_certificate_key $SSL_CERTIFICATE_KEY;\n
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;\n
    ssl_ciphers HIGH:!aNULL:!MD5;\n"

echo -e $HEADER > /etc/nginx/nginx.conf

i=0
while :
do
    s="CLOUD_MAP_$i"

    if [[ -z ${!s} ]];
    then
        break
    fi

    target=$(echo ${!s} | cut -f1 -d "|")
    source="$(echo ${!s} | cut -f2 -d "|")"

    CMD="
    server {\n
        listen $source ssl;\n
        ssl_verify_client on;\n
        ssl_verify_depth 3;\n
        ssl_client_certificate /etc/nginx/ca/cacert.pem;\n
        proxy_pass $target;\n
    }\n\n"

    i=$(( $i + 1 ))
    echo -e $CMD >> /etc/nginx/nginx.conf

done
echo "}" >> /etc/nginx/nginx.conf

nginx -g "daemon off;"
