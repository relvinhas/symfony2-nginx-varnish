server {
    listen 8080;
    server_name www.example.com;
    rewrite ^ $scheme://example.com$request_uri? permanent;
}

server {
    listen 8080 default;
    server_name example.com;

    root /var/www/example.com/current/web;

    access_log /var/www/example.com/logs/access.log;
    error_log  /var/www/example.com/logs/error.log error;

    client_max_body_size 4M;

    index app.php index.html index.htm;

    try_files $uri $uri/ @rewrite;

    location @rewrite {
        rewrite ^/(.*)$ /app.php/$1;
    }

    location ~* \.(?:ico|css|js|gif|jpe?g|png)$ {
        expires 18h;
        add_header Cache-Control "public, must-revalidate, proxy-revalidate";
    }

    location ~ \.php {
        limit_conn  default  50;

        try_files $uri =404;

        fastcgi_index app.php;
        fastcgi_pass 127.0.0.1:9000;

        include fastcgi_params;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_param PATH_INFO $fastcgi_path_info;
        fastcgi_param PATH_TRANSLATED $document_root$fastcgi_path_info;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param  SERVER_PORT 80;
        fastcgi_param  SERVER_NAME example.com;
    }

    location ~ /\.ht {
        deny all;
    }
}