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

# Exportar o projeto para web
RUN mkdir -p /var/www/html/
RUN godot --headless --export-debug "Web" /var/www/html/index.html

# Configurar nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Script de inicialização para ajustar porta e outras configurações em runtime
COPY --chmod=755 ./start.sh /start.sh

# Health check para o Coolify
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:$PORT/ || exit 1

# Expor a porta (Coolify pode substituir esta porta)
EXPOSE $PORT

# Iniciar o script que configura variáveis de ambiente e inicia o nginx
CMD ["/start.sh"] 