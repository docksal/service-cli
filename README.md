# CLI Docker image for Docksal

This image is focused on console tools necessary to develop LAMP stack (and other web) applications.

This image(s) is part of the [Docksal](http://docksal.io) image library.


## Features

- php/php-fpm (w/ xdebug), nodejs (via nvm), phyton, ruby
- Framework specific tools for Drupal, Wordpress, Magento
- Miscellaneous cli tools for day to day web development
- Hosting provider cli tools (Acquia, Pantheon, Platform.sh)
- Cron job scheduling
- Custom startup script support
- Web based IDE (Cloud9)


## Versions and image tag naming convention

- Stable versions
  - `2.6-php5.6`, `php5.6` - PHP 5.6 (deprecated, will be removed in v2.7)
  - `2.6-php7.0`, `php7.0` - PHP 7.0 (deprecated, will be removed in v2.7)
  - `2.6-php7.1`, `php7.1` - PHP 7.1
  - `2.6-php7.2`, `php7.2`, `latest` - PHP 7.2
  - `2.6-php7.3`, `php7.3` - PHP 7.3
- Development versions
  - `edge-php5.6` - PHP 5.6 (deprecated, will be removed in v2.7)
  - `edge-php7.0` - PHP 7.0 (deprecated, will be removed in v2.7)
  - `edge-php7.1` - PHP 7.1
  - `edge-php7.2` - PHP 7.2
  - `edge-php7.3` - PHP 7.3


## Supported languages and tools

### PHP

- php-fpm && php-cli
- xdebug
- composer
- drush (Drupal)
  - drush launcher with a fallback to a global drush 8 
  - registry_rebuild module
  - coder-8.x + phpcs
- drupal console launcher (Drupal)
- wp-cli (Wordpress)
- mg2-codegen (Magento 2)

This image uses the official `php-fpm` images from [Docker Hub](https://hub.docker.com/_/php/) as the base.  
This means that PHP and all modules are installed from source. Extra modules have to be installed in the same
manner (installing them with `apt-get` won't work).

### NodeJS

- nvm
- node
- npm
- yarn

NodeJS is installed via `nvm` in the docker user's profile inside the image (`/home/docker/.nvm`).

This image follows the LTS release cycle for NodeJS, e.g.:

    Latest LTS Version: 8.11.3 (includes npm 5.6.0)
    Latest Current Version: 10.7.0 (includes npm 6.1.0) 

If you need a different version of node, use `nvm` to install it, e.g, `nvm install 10.7.0`.

Then `nvm use 10.7.0` to use it in the current session or `nvm alias default 10.7.0` to use it by default. 

### Python

- python

Python is installed via `pyenv` in the docker user's profile inside the image (`/home/docker/.pyenv`).

By default this image use python v3.7.0

If you need a different version, use `pyenv` to install it, e.g, `pyenv install 2.7.8`.

Then `pyenv local 2.7.8` to use it in the current session or `pyenv global 2.7.8` to use it by default. 

### Ruby

- ruby
- gem
- bundler

Ruby is installed via `rvm` in the docker user's profile inside the image (`/home/docker/.rvm`).

By default this image use ruby v2.5.3

If you need a different version, use `rvm` to install it, e.g, `rvm install 2.5.1`.

Then `rvm use 2.5.1` to use it in the current session or `rvm --default use 2.5.1` to use it by default. 

### Other notable tools

- git with git-lfs
- curl, wget
- zip, unzip
- mysql, pgsql and mssql cli clients
- imagemagick
- mc
- mhsendmail
- cron

### Hosting provider tools

- Acquia Cloud API drush commands ([Acquia](https://www.acquia.com/)) 
- terminus ([Pantheon](https://pantheon.io/))
- platform ([Platform.sh](https://platform.sh/))

Also, see the [Secrets](#secrets) section below for more information on managing and using your hosting provider keys.

## Available PHP database drivers

- SQLite - via `sqlite3`, `pdo_sqlite`
- MySQL - via `mysqli`, `mysqlnd`, `pdo_mysql`
- PostgreSQL - via `pgsql`, `pdo_pgsql`
- MSSQL - via `mssql` and `pdo_dblib` for PHP 5.6; `sqlsrv` and `pdo_sqlsrv` for PHP 7.0+


## Using PHP Xdebug

Xdebug is disabled by default.

To enable it, run the image with `XDEBUG_ENABLED=1`:

```yml
cli
...
  environment:
    ...
    - XDEBUG_ENABLED=1
    ...
```

[See docs](https://docs.docksal.io/en/master/tools/xdebug) on using Xdebug for web and cli PHP debugging.


## Customizing startup

To run a custom startup script anytime the `cli` container has started, create a `startup.sh` file within the
`.docksal/services/cli` directory. Additionally, make sure that the file is executable as well so that the container
does not run into issues when attempting to execute the file.


## Scheduling cron jobs

Cron can be configured by making sure there is a `crontab` file located within `.docksal/services/cli`. The file should
follow the [standard crontab format](http://www.nncron.ru/help/EN/working/cron-format.htm).


<a name="secrets"></a>
## Secrets and integrations

`cli` can read secrets from environment variables and configure the respective integrations automatically at start.  

The recommended place store secrets in Docksal is the global `$HOME/.docksal/docksal.env` file on the host. From there, 
secrets are injected into the `cli` container's environment.

Below is the list of secrets currently supported.

`SECRET_SSH_PRIVATE_KEY`

Use to pass a private SSH key. The key will be stored in `/home/docker/.ssh/id_rsa` inside `cli` and will be considered 
by the SSH client **in addition** to the keys loaded in `docksal-ssh-agent` when establishing a SSH connection 
from within `cli`.

This is useful when you need a project stack to inherit a private SSH key that is not shared with other project stacks 
on the same host (e.g. in shared CI environments).

The value must be base64 encoded, i.e:

```bash
cat /path/to/some_key_rsa | base64
```

`SECRET_ACAPI_EMAIL` and `SECRET_ACAPI_KEY`

Credentials used to authenticate with [Acquia Cloud API](https://docs.acquia.com/acquia-cloud/api).  
Stored in `/home/docker/.acquia/cloudapi.conf` inside `cli`. 

Acquia Cloud API can be used via `ac-<command>` group of commands in Drush.

`SECRET_TERMINUS_TOKEN`

Credentials used to authenticate [Terminus](https://pantheon.io/docs/terminus) with Pantheon.
Stored in `/home/docker/.terminus/` inside `cli`.

Terminus is installed and available globally in `cli`.

`SECRET_PLATFORMSH_CLI_TOKEN`

Credentials used to authenticate with the [Platform.sh CLI](https://github.com/platformsh/platformsh-cli) tool.
Stored in `/home/docker/.platform` inside `cli`.

Platform CLI is installed and available globally in `cli`.


## Git configuration

When working with git from within the image, it will ask for the `user.email` and `user.name` set before you can commit.
These can be passed as environment variables and will be applied at the container startup.

```
GIT_USER_EMAIL="git@example.com"
GIT_USER_NAME="Docksal CLI"
``` 


<a name="ide"></a>
## Web based IDE (Cloud9)

[Cloud9](https://c9.github.io/core/) is a free, open-source online IDE.

Starting with version 2.3, there is the `ide` flavor of the images, which comes with Cloud9 pre-installed, e.g.:

```
2.4-php5.6-ide
2.4-php7.0-ide
2.4-php7.1-ide
2.4-php7.2-ide
2.4-php7.3-ide
``` 

[See docs](https://docs.docksal.io/en/master/tools/cloud9/) for using Cloud 9 in Docksal.
