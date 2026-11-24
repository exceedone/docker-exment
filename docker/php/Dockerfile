ARG PHP_VERSION

# Debian 13 (trixie): the same as the SQL Server driver below
FROM php:${PHP_VERSION}-fpm-trixie

# install php-ext
# gd with FreeType: the 2D barcode labels write their text with imagettftext()
RUN apt-get update && apt-get install -y git wget gnupg vim unzip libxml2-dev libpng-dev libjpeg62-turbo-dev libfreetype6-dev libzip-dev libonig-dev default-mysql-client libldap2-dev\
  && docker-php-ext-configure gd --with-freetype --with-jpeg\
  && docker-php-ext-install mbstring dom gd zip pdo_mysql ftp ldap\
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# install pre sql server driver (Microsoft's packages for Debian 13)
RUN curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg \
  && echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/microsoft-prod.gpg] https://packages.microsoft.com/debian/13/prod trixie main" > /etc/apt/sources.list.d/msprod.list \
  && apt-get update \
  && apt-get install -y unixodbc-dev libgssapi-krb5-2 \
  && ACCEPT_EULA=Y apt-get install -y msodbcsql18 mssql-tools18 \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# install sql server driver (5.13: PHP 8.3 and 8.4)
RUN pecl install sqlsrv-5.13.3 && pecl install pdo_sqlsrv-5.13.3 && docker-php-ext-enable sqlsrv && docker-php-ext-enable pdo_sqlsrv

# install PCOV for fast code coverage (disabled by default; enabled per-run via -d pcov.enabled=1)
RUN pecl install pcov-1.0.12 && docker-php-ext-enable pcov

# install composer: the binary of the official image (a fixed version, no installer to check)
COPY --from=composer:2.11 /usr/bin/composer /usr/local/bin/composer

WORKDIR /var/www/exment
