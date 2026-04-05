# Stage 1: Build Vue/TypeScript assets
FROM node:22-alpine AS build-assets
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# Stage 2: Production PHP 8.3 Environment
FROM php:8.3-fpm-alpine
WORKDIR /var/www/html

# Install Production Dependencies & PHP Extensions
RUN apk add --no-cache nginx libpng-dev libzip-dev zip unzip mariadb-client
RUN docker-php-ext-install pdo_mysql bcmath gd zip

# Copy Code & Compiled Assets
COPY . .
RUN rm -rf node_modules tests
COPY --from=build-assets /app/public/build ./public/build

# Laravel 13 Permissions
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# Copy Nginx Config
COPY .docker/nginx.conf /etc/nginx/http.d/default.conf

EXPOSE 80
CMD ["sh", "-c", "nginx && php-fpm"]