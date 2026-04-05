# Stage 1: The Build Room (Need both PHP and Node here)
FROM php:8.4-fpm-alpine AS builder

WORKDIR /app

# Install System Deps + Node + Composer
RUN apk add --no-cache nodejs npm libpng-dev libzip-dev zip unzip mariadb-client
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql bcmath gd zip

# Copy everything and build
COPY . .
RUN composer install --no-dev --optimize-autoloader
RUN npm install
# Wayfinder will now find 'php' and succeed here:
RUN npm run build

# Stage 2: The Production Room (Keep it slim)
FROM php:8.4-fpm-alpine
WORKDIR /var/www/html

RUN apk add --no-cache nginx libpng-dev libzip-dev zip unzip
RUN docker-php-ext-install pdo_mysql bcmath gd zip

# Copy only the necessary bits from the builder
COPY --from=builder /app /var/www/html
RUN rm -rf node_modules tests

# Permissions and Config
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache
COPY .docker/nginx.conf /etc/nginx/http.d/default.conf

EXPOSE 80
CMD ["sh", "-c", "nginx && php-fpm"]