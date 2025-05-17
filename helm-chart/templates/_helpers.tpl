{{/*
Generate the content for the NGINX configuration.
*/}}
{{- define "nginx.configmap.content" -}}
{{- range .Values.sites }}
server {
    {{ if .apex }}
    server_name {{ .host }};
    {{ else if .subdomain }}
    server_name {{ .subdomain }}.{{ .host }};
    {{ else }}
    server_name {{ .name }}.{{ .host }};
    {{ end }}
    listen 80;
    gzip on;
    gzip_disable "msie6";
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_buffers 16 8k;
    gzip_types text/plain text/html text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
    
    proxy_buffering off;
    proxy_intercept_errors on;
    proxy_buffer_size 16k;
    proxy_buffers 4 32k;
    proxy_busy_buffers_size 64k;
    
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    
    resolver 1.1.1.1 valid=300s ipv6=off;
    proxy_hide_header x-amz-request-id;
    proxy_hide_header x-minio-deployment-id;

    location ~ ^([^.?]*[^/])$ {
        return 301 $1/;
    }
    
    location / {
        rewrite ^/$ /{{ $.Values.bucket }}/{{ .name }}/index.html break;
        rewrite ^/(.+)/$ /{{ $.Values.bucket }}/{{ .name }}/$1/index.html break;
        rewrite ^/(.+)$ /{{ $.Values.bucket }}/{{ .name }}/$1 break;
        
        proxy_pass {{ .minioURL }}/{{ $.Values.bucket }}/{{ .name }};
        proxy_set_header Host {{ .minioHost }};
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        proxy_ssl_server_name on;
        proxy_ssl_verify off;
        error_page 404 {{ .errorPage }};

        proxy_hide_header Cache-Control;
        add_header Cache-Control "public, max-age={{ $.Values.maxAge }}, stale-while-revalidate={{ $.Values.staleWhileRevalidate }}, stale-if-error={{ $.Values.staleIfError }}" always;

    }
}
{{- end }}
{{- end }}
