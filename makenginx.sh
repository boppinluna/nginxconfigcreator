#!/bin/bash
echo "Enter /var/www folder name"
read foldername
echo "Enter domain name; e.g. example.com"
read domainname

echo "server {
    listen 80;
    server_name $domainname;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $domainname;

    root /var/www/$foldername;
    index index.php;

    access_log /var/log/nginx/$domainname-access.log;
    error_log  /var/log/nginx/$domainname-error.log error;

    # allow larger file uploads and longer script runtimes
    client_max_body_size 100m;
    client_body_timeout 120s;

    sendfile off;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/$domainname/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$domainname/privkey.pem;
    ssl_session_cache shared:SSL:10m;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers \"ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384\";
    ssl_prefer_server_ciphers on;

    # See https://hstspreload.org/ before uncommenting the line below.
    # add_header Strict-Transport-Security \"max-age=15768000; preload;\";
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection \"1; mode=block\";
    add_header X-Robots-Tag none;
    add_header Content-Security-Policy \"frame-ancestors 'self'\";
    add_header X-Frame-Options DENY;
    add_header Referrer-Policy same-origin;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/run/php/php7.2-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param PHP_VALUE \"upload_max_filesize = 100M \n post_max_size=100M\";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include /etc/nginx/fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}" > /etc/nginx/sites-available/$domainname.conf

sleep 1
chmod +x /etc/nginx/sites-available/$domainname.conf
sleep 1
sudo ln -s /etc/nginx/sites-available/$domainname.conf /etc/nginx/sites-enabled/$domainname.conf

echo "Do you want to create a certbot SSL certificate for this domain? Y/N"
read sslcert

if [[ ( $sslcert == "Y" || $sslcert == "y" ) ]]
then
    sudo service nginx stop
    sudo certbot certonly -d $domainname
    sudo service nginx start
    exit $?
fi

echo "Created config scripts for $domainname. Would you like to reload nginx? Y/N"
read reloadnginx
if [[ ( $reloadnginx == "Y" || $reloadnginx == "y" ) ]]
then
    sudo service nginx restart
    sleep 2
fi
exit $?
