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

    # Try to serve static files directly first
    location ~* \.(svg|min\.js|js|css|png|jpg|jpeg|gif|ico|woff|woff2|ttf|eot)$ {
        rewrite ^/(.*)$ /{{ $.Values.bucket }}/{{ .name }}/$1 break;
        proxy_pass {{ .minioURL }};
        proxy_set_header Host {{ .minioHost }};
        add_header Cache-Control "public, max-age={{ $.Values.maxAge }}, stale-while-revalidate={{ $.Values.staleWhileRevalidate }}" always;
    }

    location / {
        rewrite /$ ${request_uri}index.html last;
        proxy_pass {{ .minioURL }}/{{ .name }}/;
        proxy_redirect     off;
    }
}
{{- end }}
{{- end }}
