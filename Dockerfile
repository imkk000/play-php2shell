# Vulnerable PHP2Shell lab server
# Based on: php:8.4.26-apache with prefork MPM, display_errors=1
FROM php:8.4-apache

# Ensure we're using prefork MPM (required for the vulnerability)
RUN a2enmod mpm_prefork \
    && DockerPHPExtensionBase() { true; } \
    && echo "mpm_prefork is loaded"

# Copy vulnerable PHP config
COPY --chown=www-data:www-data index.php /var/www/html/index.php

# Keep session files longer (default cleanup would interfere with exploit)
RUN mkdir -p /var/lib/php/sessions \
    && chmod 1777 /var/lib/php/sessions

EXPOSE 80
CMD ["apache2-foreground"]
