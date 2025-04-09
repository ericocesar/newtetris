FROM ubuntu:20.04

# Evitar perguntas durante a instalação
ENV DEBIAN_FRONTEND=noninteractive

# Variáveis de ambiente para configuração do Coolify
ENV PORT=80
ENV HOST=0.0.0.0
ENV PUBLIC_URL="https://tetris.host.webck.com.br"

# Instalar dependências
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    wget \
    unzip \
    python3 \
    nginx \
    curl \
    net-tools \
    vim \
    file \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Instalar Godot (headless)
WORKDIR /tmp
RUN wget https://github.com/godotengine/godot/releases/download/4.2-stable/Godot_v4.2-stable_linux.x86_64.zip \
    && unzip Godot_v4.2-stable_linux.x86_64.zip \
    && mv Godot_v4.2-stable_linux.x86_64 /usr/local/bin/godot \
    && chmod +x /usr/local/bin/godot

# Instalar Godot Export Template
RUN mkdir -p /root/.local/share/godot/export_templates/4.2.stable/ \
    && wget https://github.com/godotengine/godot/releases/download/4.2-stable/Godot_v4.2-stable_export_templates.tpz \
    && unzip Godot_v4.2-stable_export_templates.tpz \
    && mv templates/* /root/.local/share/godot/export_templates/4.2.stable/ \
    && rm -rf templates Godot_v4.2-stable_export_templates.tpz Godot_v4.2-stable_linux.x86_64.zip

# Configurar diretório de trabalho
WORKDIR /app
COPY . .

# Garantir que a pasta de exportação exista
RUN mkdir -p /app/build/web

# Exportar o projeto para web - garantindo que todas as opções necessárias estejam habilitadas
RUN mkdir -p /var/www/html/
RUN godot --headless --export-debug "Web" /var/www/html/index.html

# Verificar permissões dos arquivos WASM
RUN chmod 644 /var/www/html/*.wasm || true
RUN file /var/www/html/*.wasm || true
RUN ls -la /var/www/html/

# Configurar nginx - remover configurações padrão para evitar conflitos
RUN rm -rf /etc/nginx/sites-enabled/default /etc/nginx/sites-available/default

# Criar diretório de cache e logs
RUN mkdir -p /var/cache/nginx /var/log/nginx && \
    chown -R www-data:www-data /var/cache/nginx /var/log/nginx

# Copiar nossa configuração do nginx e tipos MIME
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY mime.types /etc/nginx/mime.types

# Configurar o Nginx para usar nossa lista de tipos MIME
RUN echo 'include /etc/nginx/mime.types;' > /etc/nginx/conf.d/mime.conf

# Criar um arquivo de teste para verificar se o servidor está funcionando
RUN echo "Servidor está online" > /var/www/html/healthcheck.txt

# Script de inicialização para ajustar porta e outras configurações em runtime
COPY --chmod=755 ./start.sh /start.sh

# Health check para o Coolify - aumentando o timeout e retries
HEALTHCHECK --interval=30s --timeout=15s --start-period=10s --retries=5 \
  CMD curl -f http://localhost:$PORT/healthcheck.txt || exit 1

# Expor a porta (Coolify pode substituir esta porta)
EXPOSE $PORT

# Iniciar o script que configura variáveis de ambiente e inicia o nginx
CMD ["/start.sh"] 