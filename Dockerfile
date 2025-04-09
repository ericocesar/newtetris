FROM ubuntu:20.04

# Evitar perguntas durante a instalação
ENV DEBIAN_FRONTEND=noninteractive

# Instalar dependências
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    wget \
    unzip \
    python3 \
    nginx \
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
COPY nginx.conf /etc/nginx/sites-available/default

# Expor a porta 80
EXPOSE 80

# Iniciar nginx em primeiro plano
CMD ["nginx", "-g", "daemon off;"] 