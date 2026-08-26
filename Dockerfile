# ── Stage 1: Build do Flutter Web ──────────────────────────────────────────────
FROM ubuntu:22.04 AS build-env

# Evita interações durante a instalação de pacotes
ENV DEBIAN_FRONTEND=noninteractive

# Instala dependências básicas do sistema
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Baixa o Flutter SDK diretamente do CDN oficial do Google
WORKDIR /sdks
RUN curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.29.0-stable.tar.xz \
    && tar xf flutter_linux_3.29.0-stable.tar.xz \
    && rm flutter_linux_3.29.0-stable.tar.xz

ENV PATH="/sdks/flutter/bin:${PATH}"

# Configura exceção de diretório seguro do Git e desabilita telemetria
RUN git config --global --add safe.directory /sdks/flutter \
 && git config --global --add safe.directory /app \
 && flutter config --no-analytics

WORKDIR /app

# Copia dependências primeiro para aproveitar o cache do Docker
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copia o código-fonte da aplicação
COPY . .

# Compila a versão web em modo release
RUN flutter build web --release

# ── Stage 2: Nginx para servir a aplicação ────────────────────────────────────
FROM nginx:alpine

# Copia os arquivos compilados da etapa anterior
COPY --from=build-env /app/build/web /usr/share/nginx/html

# Copia a configuração personalizada do Nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
