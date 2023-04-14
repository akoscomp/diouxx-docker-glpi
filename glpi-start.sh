#!/bin/bash

#Control of the version choice or taking the latest
[[ ! "$VERSION_GLPI" ]] \
	&& VERSION_GLPI=$(curl -s https://api.github.com/repos/glpi-project/glpi/releases/latest | grep tag_name | cut -d '"' -f 4)

if [[ -z "${TIMEZONE}" ]]; then echo "TIMEZONE is unset"; 
else 
echo "date.timezone = \"$TIMEZONE\"" > /etc/php/8.1/apache2/conf.d/timezone.ini;
echo "date.timezone = \"$TIMEZONE\"" > /etc/php/8.1/cli/conf.d/timezone.ini;
fi

FOLDER_GLPI=glpi/
FOLDER_GLPI_FILES=glpi_files/
FOLDER_GLPI_CONFIG=glpi_config/
FOLDER_WEB=/var/www/

#check if TLS_REQCERT is present
if !(grep -q "TLS_REQCERT" /etc/ldap/ldap.conf)
then
	echo "TLS_REQCERT isn't present"
    echo -e "TLS_REQCERT\tnever" >> /etc/ldap/ldap.conf
fi

#Downloading and extracting GLPI sources
if [ "$(ls ${FOLDER_WEB}${FOLDER_GLPI})" ];
then
	echo "GLPI is already installed"
else
	SRC_GLPI=$(curl -s https://api.github.com/repos/glpi-project/glpi/releases/tags/${VERSION_GLPI} | jq .assets[0].browser_download_url | tr -d \")
	TAR_GLPI=$(basename ${SRC_GLPI})

	wget -P ${FOLDER_WEB} ${SRC_GLPI}
	tar -xzf ${FOLDER_WEB}${TAR_GLPI} -C ${FOLDER_WEB}
	rm -Rf ${FOLDER_WEB}${TAR_GLPI}
	mkdir -p ${FOLDER_WEB}${FOLDER_GLPI_CONFIG}
	mkdir -p ${FOLDER_WEB}${FOLDER_GLPI_FILES}
	chown -R www-data:www-data ${FOLDER_WEB}${FOLDER_GLPI_CONFIG}
	chown -R www-data:www-data ${FOLDER_WEB}${FOLDER_GLPI_FILES}
fi

#Changing the default vhost
echo -e "<VirtualHost *:80>\n\tDocumentRoot ${FOLDER_WEB}${FOLDER_GLPI}public\n\n\t<Directory ${FOLDER_WEB}${FOLDER_GLPI}public>\n\t\tRequire all granted\n\t\tRewriteEngine On\n\t\tRewriteCond %{REQUEST_FILENAME} !-f\n\t\tRewriteRule ^(.*)$ index.php [QSA,L]\n\t</Directory>\n\n\tErrorLog /var/log/apache2/error-glpi.log\n\tLogLevel warn\n\tCustomLog /var/log/apache2/access-glpi.log combined\n</VirtualHost>" > /etc/apache2/sites-available/000-default.conf

#Add scheduled task by cron and enable
echo -e "#SHELL=/bin/bash\nGLPI_VAR_DIR=${FOLDER_WEB}${FOLDER_GLPI_FILES}\nGLPI_CONFIG_DIR=${FOLDER_WEB}${FOLDER_GLPI_CONFIG}\n*/2 * * * * www-data /usr/bin/php /var/www/glpi/front/cron.php &>/dev/null" >> /etc/cron.d/glpi
#Start cron service
service cron start

#Enable apache rewrite module
a2enmod rewrite && service apache2 restart && service apache2 stop

#Launch apache service in the foreground
/usr/sbin/apache2ctl -D FOREGROUND
