#!/bin/bash

# Script de inicialização para configurar o ambiente antes de iniciar o nginx

# Substituir a porta no arquivo de configuração do nginx
sed -i "s/listen 80/listen $PORT/g" /etc/nginx/conf.d/default.conf
sed -i "s/listen \[::\]:80/listen \[::\]:$PORT/g" /etc/nginx/conf.d/default.conf

# Se PUBLIC_URL estiver definido, configura o servidor_name correspondente
if [ ! -z "$PUBLIC_URL" ]; then
    # Extrair o domínio da URL pública (remove http:// ou https://)
    DOMAIN=$(echo $PUBLIC_URL | sed -e 's|^[^/]*//||' -e 's|/.*$||')
    sed -i "s/server_name _;/server_name $DOMAIN;/g" /etc/nginx/conf.d/default.conf
    echo "Configurado para domínio: $DOMAIN"
fi

# Log das configurações
echo "Iniciando servidor na porta: $PORT"
echo "URL pública configurada: $PUBLIC_URL"

# Verificar se temos todos os arquivos necessários
if [ ! -f /var/www/html/index.html ]; then
    echo "ERRO: Arquivo index.html não encontrado!"
    exit 1
fi

if [ ! -f /var/www/html/index.wasm ]; then
    echo "AVISO: Arquivo index.wasm não encontrado. Verifique a exportação do Godot."
fi

# Ajustar permissões
chmod -R 755 /var/www/html

# Iniciar nginx em primeiro plano
exec nginx -g "daemon off;" 