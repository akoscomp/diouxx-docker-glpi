# Project to deploy GLPI 10+ with docker

![Docker Pulls](https://img.shields.io/docker/pulls/akoscomp/glpi) ![Docker Stars](https://img.shields.io/docker/stars/akoscomp/glpi) [![](https://images.microbadger.com/badges/image/akoscomp/glpi.svg)](http://microbadger.com/images/akoscomp/glpi "Get your own image badge on microbadger.com") ![Docker Cloud Automated build](https://img.shields.io/docker/cloud/automated/akoscomp/glpi)

# Summary
Make backup before upgrade and migration from old installation.
This image is a secure instalation of GLPI 10+ version. Use the new recomandation to store the data and the config files outside of web folder.
The image default instalation install separete GLPI_FILES and GLPI_CONFIG. The image can switch automaticaly from an old structure to a new structure.
If you want to keep the files and config folder in glpi webroot folder, remove the GLPI_VAR_DIR and GLPI_CONFIG_DIR environment variables.

# Table of Contents
- [Project to deploy GLPI with docker](#project-to-deploy-glpi-with-docker)
- [Table of Contents](#table-of-contents)
- [Introduction](#introduction)
  - [Default accounts](#default-accounts)
- [Deploy with CLI](#deploy-with-cli)
  - [Deploy GLPI](#deploy-glpi)
  - [Deploy GLPI with existing database](#deploy-glpi-with-existing-database)
  - [Deploy GLPI with database and persistence data](#deploy-glpi-with-database-and-persistence-data)
  - [Deploy a specific release of GLPI](#deploy-a-specific-release-of-glpi)
- [Deploy with docker-compose](#deploy-with-docker-compose)
  - [Deploy without persistence data ( for quickly test )](#deploy-without-persistence-data--for-quickly-test-)
  - [Deploy a specific release](#deploy-a-specific-release)
  - [Deploy with persistence data](#deploy-with-persistence-data)
    - [mariadb.env](#mariadbenv)
    - [docker-compose .yml](#docker-compose-yml)
- [Environnment variables](#environnment-variables)
  - [TIMEZONE](#timezone)

# Introduction

Install and run an GLPI 10+ instance with docker

## Default accounts

More info in the 📄[Docs](https://glpi-install.readthedocs.io/en/latest/install/wizard.html#end-of-installation)

| Login/Password     	| Role              	|
|--------------------	|-------------------	|
| glpi/glpi          	| admin account     	|
| tech/tech          	| technical account 	|
| normal/normal      	| "normal" account  	|
| post-only/postonly 	| post-only account 	|


# Deploy GLPI with docker-compose

## Deploy without persistence data ( for quickly test )
```yaml
version: "3.8"

services:
#MariaDB Container
  mariadb:
    image: mariadb:10.7
    container_name: mariadb
    hostname: mariadb
    env_file:
      - ./mariadb.env

#GLPI Container
  glpi:
    image: akoscomp/glpi
    container_name : glpi
    hostname: glpi
    ports:
      - "80:80"
```

## Deploy a specific release

```yaml
version: "3.8"

services:
#MariaDB Container
  mariadb:
    image: mariadb:10.7
    container_name: mariadb
    hostname: mariadb
    environment:
      - MARIADB_ROOT_PASSWORD=password
      - MARIADB_DATABASE=glpidb
      - MARIADB_USER=glpi_user
      - MARIADB_PASSWORD=glpi

#GLPI Container
  glpi:
    image: akoscomp/glpi
    container_name : glpi
    hostname: glpi
    environment:
      - VERSION_GLPI=10.0.7
    ports:
      - "80:80"
```

## Deploy with persistence data

To deploy with docker compose, you use *docker-compose.yml* and *mariadb.env* file.
You can modify **_mariadb.env_** to personalize settings like :

* MariaDB root password
* GLPI database
* GLPI user database
* GLPI user password


### mariadb.env
```
MARIADB_ROOT_PASSWORD=diouxx
MARIADB_DATABASE=glpidb
MARIADB_USER=glpi_user
MARIADB_PASSWORD=glpi
```

### docker-compose .yml
```yaml
version: "3.8"

services:
#MariaDB Container
  mariadb:
    image: mariadb:10.7
    container_name: mariadb
    hostname: mariadb
    volumes:
      - ./mariadb:/var/lib/mysql
    env_file:
      - ./mariadb.env
    restart: always

#GLPI Container
  glpi:
    image: akoscomp/glpi
    container_name : glpi
    hostname: glpi
    ports:
      - "80:80"
    volumes:
      - /etc/timezone:/etc/timezone:ro
      - /etc/localtime:/etc/localtime:ro
      - ./glpi_data:/var/www
    environment:
      - TIMEZONE=Europe/Brussels
      - GLPI_VAR_DIR=/var/www/glpi_files
      - GLPI_CONFIG_DIR=/var/www/glpi_config
    restart: always
```

To deploy, just run the following command on the same directory as files

```sh
docker compose up -d
```

# Environnment variables

## TIMEZONE
If you need to set timezone for Apache and PHP

## GLPI_VAR_DIR
You can set custom files directory

## GLPI_CONFIG_DIR
You can set custom config directory

## VERSION_GLPI
Can specify specific glpi release.
The image can't upgrade the actual version, it works only for new installations.
