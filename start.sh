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

# Garantir que o diretório web existe e tem permissões corretas
mkdir -p /var/www/html
chmod -R 755 /var/www/html

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

# Verificar informações dos arquivos críticos
echo "======== INFORMAÇÕES DOS ARQUIVOS WASM ========"
file /var/www/html/*.wasm || echo "Arquivo WASM não encontrado"
echo "=============================================="

# Verificar tipos MIME configurados
echo "======== TIPOS MIME CONFIGURADOS ========"
grep -r "application/wasm" /etc/nginx/
echo "========================================"

# Verificar se temos todos os arquivos necessários
if [ ! -f /var/www/html/index.html ]; then
    echo "ERRO: Arquivo index.html não encontrado!"
    exit 1
fi

if [ ! -f /var/www/html/index.wasm ]; then
    echo "ERRO: Arquivo index.wasm não encontrado!"
    exit 1
fi

# Fazer backup do arquivo index.html original
echo "Fazendo backup do index.html original..."
cp /var/www/html/index.html /var/www/html/index.html.orig

# Adiciona headers necessários diretamente ao index.html
echo "Modificando index.html para adicionar headers de segurança diretamente..."
sed -i 's/<head>/<head>\n  <meta http-equiv="Cross-Origin-Opener-Policy" content="same-origin">\n  <meta http-equiv="Cross-Origin-Embedder-Policy" content="require-corp">/g' /var/www/html/index.html

# Verificar se a modificação foi aplicada
if grep -q "Cross-Origin-Opener-Policy" /var/www/html/index.html; then
    echo "Headers de segurança adicionados ao index.html com sucesso."
else
    echo "AVISO: Não foi possível adicionar headers de segurança ao index.html."
fi

# Ajustar permissões
echo "Ajustando permissões..."
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

# Configurar permissões específicas para WASM
echo "Configurando permissões específicas para WASM..."
chmod 644 /var/www/html/*.wasm
chmod 644 /var/www/html/*.pck
chmod 644 /var/www/html/*.js

# Verificar conteúdo do index.html
echo "======== CONTEÚDO DO INDEX.HTML ========"
grep -i wasm /var/www/html/index.html || echo "Nenhuma referência a WASM encontrada no index.html"
grep -i cross-origin /var/www/html/index.html || echo "Nenhuma referência a Cross-Origin encontrada no index.html"
echo "========================================"

# Verificar se o nginx está configurado corretamente
echo "Verificando configuração do Nginx..."
nginx -t || exit 1

# Verificar quais processos estão usando as portas relevantes
echo "======== PORTAS EM USO ========"
netstat -tulpn | grep -E ":(80|443|$PORT)"
echo "=============================="

# Iniciar nginx em primeiro plano
echo "Iniciando Nginx..."
exec nginx -g "daemon off;" 