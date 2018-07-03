# CLI Docker image for Docksal

This image is focused on console tools necessary to develop LAMP stack applications.

This image(s) is part of the [Docksal](http://docksal.io) image library.


## Versions and image tag naming convention

- Stable versions
  - `2.0-php5.6`, `php5.6` - PHP 5.6
  - `2.0-php7.0`, `php7.0` - PHP 7.0
  - `2.0-php7.1`, `php7.1` - PHP 7.1
  - `2.0-php7.2`, `php7.2`, `latest` - PHP 7.2
- Development versions
  - `edge-php5.6` - PHP 5.6
  - `edge-php7.0` - PHP 7.0
  - `edge-php7.1` - PHP 7.1
  - `edge-php7.2` - PHP 7.2


## Includes

- php
  - php-fpm && php-cli
  - xdebug
  - composer
  - drush
    - registry_rebuild
    - coder-8.x + phpcs
    - Acquia Cloud API commands
  - drupal console launcher
  - terminus (Pantheon)
  - platform (Platform.sh)
  - wp-cli
- ruby
  - ruby
  - gem
  - bundler
- nodejs
  - nodejs
  - npm, yarn
- python
- cron

Other notable tools:

- git
- curl/wget
- zip/unzip
- mysql-client
- imagemagick
- mc
- mhsendmail


## PHP database drivers support

- SQLite - via `sqlite3`, `pdo_sqlite`
- MySQL - via `mysqli`, `mysqlnd`, `pdo_mysql`
- PostgreSQL - via `pgsql`, `pdo_pgsql`
- MSSQL - via `mssql` and `pdo_dblib` for PHP 5.6; `sqlsrv` and `pdo_sqlsrv` for PHP 7.0+


## Xdebug

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

See [docs](https://docs.docksal.io/en/master/tools/xdebug) on using Xdebug for web and cli PHP debugging.

## Customizing Startup

To run a custom startup script anytime the `cli` container has started create a `startup.sh` file within the
`.docksal/services/cli` directory. Additionally, make sure that the file is executable as well so that the container
does not run into issues when attempting to execute the file.

## Customized Cron Configuration

Cron can be configured by making sure there is a `crontab` file located within `.docksal/services/cli`. The file should
be filled out accordingly such that it follows the standard crontab format. For more information click [here](http://www.nncron.ru/help/EN/working/cron-format.htm).

## Secrets and integrations

`cli` can read secrets from environment variables and configure the respective integrations automatically at start.  

The recommended place store secrets in Docksal is the global `$HOME/.docksal/docksal.env` file on the host. From there, 
secrets are injected into the `cli` container's environment.

Below is the list of secrets currently supported.

`SECRET_SSH_PRIVATE_KEY`

Use to pass a private SSH key. The key is stored in `/home/docker/.ssh/id_rsa` inside `cli` and will be considered 
by the SSH client **in addition** to the keys loaded in `docksal-ssh-agent` when establishing a SSH connection 
from within `cli`.

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
