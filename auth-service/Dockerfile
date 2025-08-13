FROM php:8.2-apache

RUN docker-php-ext-install pdo pdo_mysql mysqli

# Copy source
COPY src/ /var/www/html/

# Hardening-ish defaults
ENV APACHE_LOG_DIR=/var/log/apache2
