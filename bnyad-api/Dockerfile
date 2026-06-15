FROM php:8.2-cli-bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    unzip \
    libzip-dev \
    && docker-php-ext-install pdo_mysql zip \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /app

COPY composer.json composer.lock ./
RUN composer install --no-dev --optimize-autoloader --no-interaction --no-scripts

COPY . .

RUN composer dump-autoload --optimize \
    && APP_KEY=base64:ZGVwbG95a2V5ZGVwbG95a2V5ZGVwbG95a2V5ZGVwbG95= APP_URL=http://localhost php artisan package:discover --ansi \
    && mkdir -p storage/framework/cache storage/framework/sessions storage/framework/views storage/logs bootstrap/cache \
    && chmod -R 777 storage bootstrap/cache \
    && sed -i 's/\r$//' docker/start.sh \
    && chmod +x docker/start.sh

EXPOSE 8080

CMD ["docker/start.sh"]
