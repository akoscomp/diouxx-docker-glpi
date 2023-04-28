#!/bin/bash

#Control of the version choice or taking the latest
[[ ! "$VERSION_GLPI" ]] \
	&& VERSION_GLPI=$(curl -s https://api.github.com/repos/glpi-project/glpi/releases/latest | grep tag_name | cut -d '"' -f 4)

if [[ -z "${TIMEZONE}" ]]; then echo "TIMEZONE is unset"; 
else 
echo "date.timezone = \"$TIMEZONE\"" > /etc/php/8.1/apache2/conf.d/timezone.ini;
echo "date.timezone = \"$TIMEZONE\"" > /etc/php/8.1/cli/conf.d/timezone.ini;
fi

#check if TLS_REQCERT is present
if !(grep -q "TLS_REQCERT" /etc/ldap/ldap.conf)
then
	echo "TLS_REQCERT isn't present"
    echo -e "TLS_REQCERT\tnever" >> /etc/ldap/ldap.conf
fi

FOLDER_WEB=/var/www
FOLDER_GLPI=/var/www/glpi

if [ "$(ls ${FOLDER_GLPI})" ];
then
	echo "GLPI is already installed"
else
	SRC_GLPI=$(curl -s https://api.github.com/repos/glpi-project/glpi/releases/tags/${VERSION_GLPI} | jq .assets[0].browser_download_url | tr -d \")
	TAR_GLPI=$(basename ${SRC_GLPI})

	wget -P ${FOLDER_WEB} ${SRC_GLPI}
	tar -xzf ${FOLDER_WEB}/${TAR_GLPI} -C ${FOLDER_WEB}
	rm -Rf ${FOLDER_WEB}/${TAR_GLPI}
fi

if [[ -z "${GLPI_VAR_DIR}" ]]; then
  echo "Files dir don't set, use ${FOLDER_GLPI}/files"
  GLPI_VAR_DIR=${FOLDER_GLPI}/files
else
  mkdir -p ${GLPI_VAR_DIR}
  ### Fix GLPI install error if use external GLPI_FILES folder.
  if [ -d "${GLPI_VAR_DIR}/_tmp" ]; then
 	  echo "GLPI data folder exists"
  else
	  echo "Fix GLPI data folder absence, move files to new location"
	  cp -r ${FOLDER_GLPI}/files/* ${GLPI_VAR_DIR}
	  rm -rf ${FOLDER_GLPI}/files
  fi
  chown -R www-data:www-data ${GLPI_VAR_DIR}
fi

if [[ -z "${GLPI_CONFIG_DIR}" ]]; then
  echo "Config dir don't set, use ${FOLDER_GLPI}/config"
  GLPI_CONFIG_DIR=${FOLDER_GLPI}/config
else
  #Test if is a new installation or migration
  mkdir -p ${GLPI_CONFIG_DIR}
  if [ ! -f "${GLPI_CONFIG_DIR}/config_db.php" ]; then
    echo "Move config files to new location"
	  cp -r ${FOLDER_GLPI}/config/* ${GLPI_CONFIG_DIR}
	  chown -R www-data:www-data ${GLPI_CONFIG_DIR}
  fi
fi

#Downloading and extracting GLPI sources

#Add scheduled task by cron
cat << EOF > /opt/yacron.jobs
---
logging:
  version: 1
  disable_existing_loggers: false
  formatters:
    simple:
      format: '%(asctime)s [%(processName)s/%(threadName)s] %(levelname)s (%(name)s): %(message)s'
  handlers:
    console:
      class: logging.StreamHandler
      level: DEBUG
      formatter: simple
      stream: ext://sys.stdout
  root:
    level: ERROR
    handlers:
      - console
jobs:
  - name: glpi
    command: /usr/bin/php /var/www/glpi/front/cron.php
    schedule:
      minute: "*/2"
    user: www-data
    environment:
      - key: GLPI_VAR_DIR
        value: ${GLPI_VAR_DIR}
      - key: GLPI_CONFIG_DIR
        value: ${GLPI_CONFIG_DIR}
EOF

if [ -f "/opt/yacron" ];
then
	echo "Start yacron service"
	/opt/yacron -c /opt/yacron.jobs &
else
	echo "/opt/yacron don't exists"
fi

#Changing the default vhost
cat << EOF > /etc/apache2/sites-available/000-default.conf
<VirtualHost *:80>
  DocumentRoot ${FOLDER_GLPI}/public
  <Directory ${FOLDER_GLPI}/public>
    Require all granted
    RewriteEngine On
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteRule ^(.*)$ index.php [QSA,L]
  </Directory>
  ErrorLog /var/log/apache2/error-glpi.log
  LogLevel warn
  CustomLog /var/log/apache2/access-glpi.log combined
</VirtualHost>
EOF

#Enable apache rewrite module
a2enmod rewrite && service apache2 restart && service apache2 stop

#Launch apache service in the foreground
/usr/sbin/apache2ctl -D FOREGROUND
