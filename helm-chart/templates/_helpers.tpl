{{/*
Generate the content for the NGINX configuration.
*/}}
{{- define "nginx.configmap.content" -}}
{{- range .Values.sites }}
server {
    listen 80;
    server_name {{ .name }}.{{ .host }};

    gzip on;
    gzip_disable "msie6";
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_buffers 16 8k;
    gzip_types text/plain text/html text/css application/json application/javascript application/x-javascript text/xml application/xml application/xml+rss text/javascript image/svg+xml image/webp;

    proxy_buffering off;
    proxy_intercept_errors on;

    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;

    proxy_hide_header x-amz-request-id;
    proxy_hide_header x-minio-deployment-id;

    # Redirect trailing slashes
    rewrite ^/(.*)/$ /$1 permanent;

    # Try to serve static files directly first
    location ~* \.(svg|webp|png|min\.js|js|css|jpg|jpeg|gif|ico|woff|woff2|ttf|eot)$ {
        # Don't add the site name to the path since it's already in the bucket structure
        rewrite ^/(.*)$ /{{ $.Values.bucket }}/wwdev/$1 break;
        proxy_pass {{ .minioURL }};
        proxy_set_header Host {{ .minioHost }};
        add_header Cache-Control "public, max-age={{ $.Values.maxAge }}, stale-while-revalidate={{ $.Values.staleWhileRevalidate }}" always;
    }

    location / {
        # Handle root path
        rewrite ^/$ /{{ $.Values.bucket }}/wwdev/index.html break;
        
        # Handle directory paths (without trailing slash since we redirect it above)
        rewrite ^/([^.]+)$ /{{ $.Values.bucket }}/wwdev/$1/index.html break;
        
        # Handle all other files
        rewrite ^/(.+)$ /{{ $.Values.bucket }}/wwdev/$1 break;
        
        proxy_pass {{ .minioURL }};
        proxy_set_header Host {{ .minioHost }};
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        proxy_ssl_server_name on;
        proxy_ssl_verify off;
        error_page 404 {{ .errorPage }};

        add_header Cache-Control "public, max-age={{ $.Values.maxAge }}, stale-while-revalidate={{ $.Values.staleWhileRevalidate }}" always;
    }
}
{{- end }}
{{- end }}
