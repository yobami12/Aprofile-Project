FROM php:8.2-apache

RUN docker-php-ext-install pdo pdo_mysql mysqli

COPY src/ /var/www/html/

ENV APACHE_LOG_DIR=/var/log/apache2
