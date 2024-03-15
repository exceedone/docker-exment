ARG PHP_VERSION

FROM php:${PHP_VERSION}-fpm

# install php-ext
RUN apt-get update && apt-get install -y git wget gnupg vim unzip lsb-release inetutils-tools libxml2-dev libpng-dev libzip-dev libonig-dev libldap2-dev\
  && docker-php-ext-install mbstring dom gd zip pdo_mysql ftp ldap\
  && apt-get clean
RUN wget https://dev.mysql.com/get/mysql-apt-config_0.8.29-1_all.deb
RUN DEBIAN_FRONTEND=noninteractive dpkg -i mysql-apt-config_0.8.29-1_all.deb
RUN apt-get update
RUN apt install -y mysql-client

# install pre sql server driver
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
  && curl https://packages.microsoft.com/config/ubuntu/20.04/prod.list | tee /etc/apt/sources.list.d/msprod.list \
  && apt-get update \
  && apt-get install -y unixodbc-dev=2.3.7 unixodbc=2.3.7 odbcinst1debian2=2.3.7 odbcinst=2.3.7 libgssapi-krb5-2 \
  && ACCEPT_EULA=Y apt-get install -y msodbcsql17 mssql-tools

# install sql server driver
RUN pecl install sqlsrv && pecl install pdo_sqlsrv && docker-php-ext-enable sqlsrv && docker-php-ext-enable pdo_sqlsrv

# install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

COPY .env /var/www/exment/.env
WORKDIR /var/www/exment
