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
    gzip_types text/plain text/html text/css application/json application/javascript application/x-javascript text/xml application/xml application/xml+rss text/javascript;

    proxy_buffering off;
    proxy_intercept_errors on;

    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;

    proxy_hide_header x-amz-request-id;
    proxy_hide_header x-minio-deployment-id;

    location / {
        # Handle root path
        rewrite ^/$ /{{ $.Values.bucket }}/{{ .name }}/index.html break;
        # Handle paths without trailing slash
        rewrite ^/([^.]+)$ /$1/ permanent;
        # Handle paths with trailing slash
        rewrite ^/(.+)/$ /{{ $.Values.bucket }}/{{ .name }}/$1/index.html break;
        # Handle direct file access
        rewrite ^/(.+)$ /{{ $.Values.bucket }}/{{ .name }}/$1 break;
        
        # Use the parameterized backend URL.
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
