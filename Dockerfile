# Stage 1: build
FROM php:8.1-cli AS builder

# Install system dependencies
RUN apt-get update && apt-get install -y \
    zip unzip git curl libzip-dev \
 && docker-php-ext-install pdo_mysql zip

WORKDIR /app

# Grab Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Install PHP dependencies
COPY composer.json composer.lock ./
RUN composer install --no-dev --optimize-autoloader

# Build frontend assets using npm
COPY package.json package-lock.json ./
RUN npm install

# Copy application source and build assets
COPY . .
RUN npm run build

# Stage 2: runtime
FROM php:8.1-cli

WORKDIR /app

# Copy built application and vendor folder
COPY --from=builder /app /app

# Expose the port the app will run on
EXPOSE 8000

# Create storage symlink\RUN php artisan storage:link

# Start Laravel
CMD ["sh", "-c", "php artisan serve --host=0.0.0.0 --port=${PORT}"]
