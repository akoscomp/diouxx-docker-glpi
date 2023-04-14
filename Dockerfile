#We choose a debian
FROM debian:11.6

LABEL org.opencontainers.image.authors="github@datanest.ro"


#Do not ask questions at installation
ENV DEBIAN_FRONTEND noninteractive

#Installation of php repositories 8.1
RUN apt update \ 
&& apt --yes install apt-transport-https lsb-release ca-certificates curl \
&& curl -sSLo /usr/share/keyrings/deb.sury.org-php.gpg https://packages.sury.org/php/apt.gpg \ 
&& sh -c 'echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list' \
&& apt update

#Install apache and php 8.1 with extension
RUN apt install --yes --no-install-recommends \
apache2 \
php8.1 \
php8.1-mysql \
php8.1-ldap \
php8.1-xmlrpc \
php8.1-imap \
php8.1-curl \
php8.1-gd \
php8.1-mbstring \
php8.1-xml \
php-cas \
php8.1-intl \
php8.1-zip \
php8.1-bz2 \
cron \
wget \
ca-certificates \
jq \
libldap-2.4-2 \
libldap-common \
libsasl2-2 \
libsasl2-modules \
libsasl2-modules-db \
&& rm -rf /var/lib/apt/lists/*

#Copy and execution of the script for the installation and initialization of GLPI
COPY glpi-start.sh /opt/
RUN chmod +x /opt/glpi-start.sh
ENTRYPOINT ["/opt/glpi-start.sh"]

#Expose ports
EXPOSE 80 443
