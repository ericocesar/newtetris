FROM nginx:alpine

# Instalação de dependências
RUN apk add --no-cache bash

# Diretório de trabalho
WORKDIR /usr/share/nginx/html

# Remoção do index.html padrão do Nginx
RUN rm -rf /usr/share/nginx/html/*

# Copiar script de inicialização
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Copiar configuração do Nginx
COPY nginx.conf /etc/nginx/nginx.conf

# Copiar páginas de erro
COPY assets/404.html /usr/share/nginx/html/404.html
COPY assets/50x.html /usr/share/nginx/html/50x.html

# Expor a porta 80
EXPOSE 80

# Entrypoint
ENTRYPOINT ["/start.sh"] 