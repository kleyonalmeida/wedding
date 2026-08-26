# ── Stage 1: Build do Flutter Web ──────────────────────────────────────────────
FROM ghcr.io/cirrusci/flutter:stable AS build-env

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
