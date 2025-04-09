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

# Exportar o projeto para web
RUN mkdir -p /var/www/html/
RUN godot --headless --export-debug "Web" /var/www/html/index.html

# Criar um arquivo index.html personalizado
RUN echo '<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, user-scalable=no">
    <meta http-equiv="Cross-Origin-Opener-Policy" content="same-origin">
    <meta http-equiv="Cross-Origin-Embedder-Policy" content="require-corp">
    <title>Tetris Duelistas</title>
    <style>
        body {
            margin: 0;
            padding: 0;
            background-color: black;
            color: white;
            font-family: sans-serif;
        }
        #canvas {
            display: block;
            margin: 0 auto;
            width: 100%;
            height: 100vh;
        }
        #canvas:focus {
            outline: none;
        }
        #status {
            position: absolute;
            left: 0;
            top: 0;
            right: 0;
            bottom: 0;
            display: flex;
            justify-content: center;
            align-items: center;
            flex-direction: column;
        }
        .godot {
            font-size: 14px;
            color: #eeeeee;
            display: block;
            margin: 0 auto;
            width: 100%;
            max-width: 900px;
            text-align: center;
        }
        .spinner {
            height: 48px;
            width: 48px;
            animation: rotate 2s linear infinite;
            transform-origin: center center;
            position: absolute;
            top: 0;
            bottom: 0;
            left: 0;
            right: 0;
            margin: auto;
        }
        .spinner .path {
            stroke-dasharray: 1, 200;
            stroke-dashoffset: 0;
            stroke: #7de8e8;
            animation: dash 1.5s ease-in-out infinite;
            stroke-linecap: round;
        }
        @keyframes rotate {
            100% {
                transform: rotate(360deg);
            }
        }
        @keyframes dash {
            0% {
                stroke-dasharray: 1, 200;
                stroke-dashoffset: 0;
            }
            50% {
                stroke-dasharray: 89, 200;
                stroke-dashoffset: -35px;
            }
            100% {
                stroke-dasharray: 89, 200;
                stroke-dashoffset: -124px;
            }
        }
    </style>
</head>
<body>
    <canvas id="canvas"></canvas>
    <div id="status">
        <div id="status-progress" style="display: none;" oncontextmenu="event.preventDefault();">
            <div id="status-progress-inner"></div>
        </div>
        <div id="status-indeterminate" style="display: none;" oncontextmenu="event.preventDefault();">
            <svg class="spinner" viewBox="25 25 50 50">
                <circle class="path" cx="50" cy="50" r="20" fill="none" stroke-width="2" stroke-miterlimit="10"></circle>
            </svg>
        </div>
        <div id="status-notice" class="godot" style="display: none;"></div>
    </div>

    <script type="text/javascript" src="index.js"></script>
    <script type="text/javascript">//<![CDATA[
        const GODOT_CONFIG = {"canvasResizePolicy":2,"executable":"index","experimentalVK":false,"fileSizes":{"index.pck":243040,"index.wasm":48954223},"focusCanvas":true,"gdextensionLibs":[]};
        var engine = new Engine(GODOT_CONFIG);

        (function() {
            const INDETERMINATE_STATUS_STEP_MS = 100;
            const statusProgress = document.getElementById("status-progress");
            const statusProgressInner = document.getElementById("status-progress-inner");
            const statusIndeterminate = document.getElementById("status-indeterminate");
            const statusNotice = document.getElementById("status-notice");

            let initializing = true;
            let statusMode = "hidden";

            let animationCallbacks = [];
            function animate(time) {
                animationCallbacks.forEach((callback) => callback(time));
                requestAnimationFrame(animate);
            }
            requestAnimationFrame(animate);

            function setStatusMode(mode) {
                if (statusMode === mode || !initializing) {
                    return;
                }
                [statusProgress, statusIndeterminate, statusNotice].forEach((elem) => {
                    elem.style.display = "none";
                });
                animationCallbacks = animationCallbacks.filter(function(value) {
                    return (value !== animateStatusIndeterminate);
                });
                switch (mode) {
                    case "progress":
                        statusProgress.style.display = "block";
                        break;
                    case "indeterminate":
                        statusIndeterminate.style.display = "block";
                        animationCallbacks.push(animateStatusIndeterminate);
                        break;
                    case "notice":
                        statusNotice.style.display = "block";
                        break;
                    case "hidden":
                        break;
                    default:
                        throw new Error("Invalid status mode");
                }
                statusMode = mode;
            }

            function animateStatusIndeterminate(ms) {
                const i = Math.floor((ms / INDETERMINATE_STATUS_STEP_MS) % 8);
                if (statusIndeterminate.children[i].style.borderTopColor === "") {
                    Array.prototype.slice.call(statusIndeterminate.children).forEach((child) => {
                        child.style.borderTopColor = "";
                    });
                    statusIndeterminate.children[i].style.borderTopColor = "#dfdfdf";
                }
            }

            function setStatusNotice(text) {
                while (statusNotice.lastChild) {
                    statusNotice.removeChild(statusNotice.lastChild);
                }
                const lines = text.split("\n");
                lines.forEach((line) => {
                    statusNotice.appendChild(document.createTextNode(line));
                    statusNotice.appendChild(document.createElement("br"));
                });
            }

            engine.setProgressFunc((current, total) => {
                if (total > 0) {
                    statusProgressInner.style.width = `${current / total * 100}%`;
                    setStatusMode("progress");
                    if (current === total) {
                        setTimeout(() => {
                            setStatusMode("indeterminate");
                        }, 500);
                    }
                } else {
                    setStatusMode("indeterminate");
                }
            });

            engine.setOnExecute(() => {
                setStatusMode("hidden");
                initializing = false;
            });

            engine.setOnExit((status) => {
                setStatusNotice(`Game crashed with status: ${status}`);
                setStatusMode("notice");
                initializing = false;
            });

            engine.setOnStdout((text) => {
                console.log(text);
            });

            engine.setOnStderr((text) => {
                console.error(text);
            });

            setStatusMode("indeterminate");
            engine.startGame("Carregando Tetris Duelistas...");
        }());
    //]]></script>
</body>
</html>' > /var/www/html/index.html.new

# Substituir o index.html do Godot pelo nosso personalizado
RUN mv /var/www/html/index.html.new /var/www/html/index.html

# Verificar permissões dos arquivos WASM
RUN chmod 644 /var/www/html/*.wasm || true
RUN file /var/www/html/*.wasm || true
RUN ls -la /var/www/html/

# Configurar nginx - remover configurações padrão para evitar conflitos
RUN rm -rf /etc/nginx/sites-enabled/default /etc/nginx/sites-available/default
RUN rm -rf /etc/nginx/conf.d/*

# Usar somente os tipos MIME padrão do Nginx para evitar duplicações
RUN mkdir -p /var/cache/nginx /var/log/nginx && \
    chown -R www-data:www-data /var/cache/nginx /var/log/nginx

# Copiar nossa configuração do nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

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