# Stage 1: build
FROM php:8.1-cli AS builder

# Install system deps
RUN apt-get update && apt-get install -y \
    zip unzip git curl libzip-dev \
 && docker-php-ext-install pdo_mysql zip

WORKDIR /app

# Grab Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Install PHP deps
COPY composer.json composer.lock ./
RUN composer install --no-dev --optimize-autoloader

# Build your frontend
COPY package.json yarn.lock ./
RUN yarn install
COPY . .
RUN yarn build

# Stage 2: runtime
FROM php:8.1-cli

WORKDIR /app

# Copy PHP deps + vendor
COPY --from=builder /app /app

# Expose the port Render sets via $PORT
EXPOSE 8000

# Create storage symlink
RUN php artisan storage:link

# Use the Render‐provided PORT env var
CMD ["sh","-c","php artisan serve --host=0.0.0.0 --port=${PORT}"]
