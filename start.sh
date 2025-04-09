#!/bin/bash

# Script de inicialização para configurar o ambiente antes de iniciar o nginx

# Informações de depuração
echo "======== AMBIENTE DE EXECUÇÃO ========"
echo "Hostname: $(hostname)"
echo "Endereço IP: $(hostname -I)"
echo "Porta configurada: $PORT"
echo "URL pública: $PUBLIC_URL"

# Certifique-se de que não há configurações duplicadas
rm -f /etc/nginx/sites-enabled/default
rm -f /etc/nginx/sites-available/default

# Criar diretórios de log se não existirem
mkdir -p /var/log/nginx
touch /var/log/nginx/error.log
touch /var/log/nginx/access.log
chmod 755 /var/log/nginx

# Substituir a porta no arquivo de configuração do nginx
sed -i "s/listen 80/listen $PORT/g" /etc/nginx/conf.d/default.conf
sed -i "s/listen \[::\]:80/listen \[::\]:$PORT/g" /etc/nginx/conf.d/default.conf

# Remover as flags "default_server" porque o Traefik já lida com isso
sed -i "s/default_server//g" /etc/nginx/conf.d/default.conf

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

# Verificar conteúdo do diretório web
echo "======== CONTEÚDO DO DIRETÓRIO WEB ========"
ls -la /var/www/html/
echo "==========================================="

# Verificar se temos todos os arquivos necessários
if [ ! -f /var/www/html/index.html ]; then
    echo "ERRO: Arquivo index.html não encontrado!"
    exit 1
fi

# Ajustar permissões
echo "Ajustando permissões..."
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

# Verificar se o nginx está configurado corretamente
echo "Verificando configuração do Nginx..."
nginx -t || exit 1

# Verificar quais processos estão usando as portas relevantes
echo "======== PORTAS EM USO ========"
netstat -tulpn | grep -E ':(80|443|8080)'
echo "=============================="

# Iniciar nginx em primeiro plano
echo "Iniciando Nginx..."
exec nginx -g "daemon off;" 