#!/bin/sh

echo "Iniciando servidor Tetris Duelistas..."

# Verificar se os arquivos do jogo estão presentes
if [ -z "$(ls -A /usr/share/nginx/html)" ]; then
    echo "AVISO: O diretório /usr/share/nginx/html está vazio. Nenhum arquivo do jogo foi montado."
    echo "Por favor, monte o diretório exportado do Godot usando: -v /caminho/para/jogo_exportado:/usr/share/nginx/html"
    
    # Criar uma página HTML de erro simples
    cat > /usr/share/nginx/html/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Tetris Duelistas - Erro</title>
    <style>
        body { font-family: Arial, sans-serif; background-color: #0F1035; color: white; text-align: center; padding-top: 50px; }
        h1 { color: #00FFFF; }
        .error { color: #FF5555; font-weight: bold; margin: 20px; padding: 20px; background-color: rgba(0,0,0,0.5); border-radius: 10px; }
        .hint { color: #AAAAAA; font-style: italic; margin-top: 30px; }
    </style>
</head>
<body>
    <h1>Tetris Duelistas</h1>
    <div class="error">
        <p>Os arquivos do jogo não foram encontrados.</p>
    </div>
    <div class="hint">
        <p>Para corrigir este problema, certifique-se de montar o diretório exportado do Godot ao iniciar o contêiner:</p>
        <code>docker run -v /caminho/para/jogo_exportado:/usr/share/nginx/html -p 80:80 tetris-duelistas</code>
    </div>
</body>
</html>
EOF
fi

# Iniciar o servidor Nginx em primeiro plano
echo "Iniciando o servidor Nginx..."
nginx -g "daemon off;" 