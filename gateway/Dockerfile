FROM php:8.2-apache

# Enable proxy, rewrite, and headers modules for reverse proxying
RUN a2enmod proxy proxy_http rewrite headers

# Replace the default site config with ours
COPY apache/000-default.conf /etc/apache2/sites-available/000-default.conf

# Copy static frontend
COPY www/ /var/www/html/

# Good defaults
ENV APACHE_LOG_DIR=/var/log/apache2
