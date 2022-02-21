# CLI Docker image for Docksal

This image focuses on console tools necessary to develop LAMP stack (and other web) applications.

This image(s) is part of the [Docksal](https://docksal.io) image library.


## Features

- Based on the official php-fpm Debian 11 (bullseye) images 
- php/php-fpm (w/ xdebug), nodejs (via nvm), python, ruby
- Framework specific tools for Drupal and Wordpress
- Miscellaneous cli tools for day to day web development
- Hosting provider cli tools (Acquia, Pantheon, Platform.sh)
- Cron job scheduling
- Custom startup script support
- [VS Code Server](https://github.com/cdr/code-server) (VS Code in the browser)
- Multi-platform images (amd64/arm64) starting with v3.0.0


## Versions and image tag naming convention

- Stable versions v3 (amd64/arm64)
  - `php7.4-3.0`, `php7.4-2`, `php7.4` - PHP 7.4
  - `php8.0-3.0`, `php8.0`, `php8.0`, `latest` - PHP 8.0
  - `php8.1-3.0`, `php8.1`, `php8.1`, `latest` - PHP 8.1
- Development versions (amd64/arm64)
  - `php7.4-edge` - PHP 7.4
  - `php8.0-edge` - PHP 8.0
  - `php8.1-edge` - PHP 8.0
- Previous stable versions v3 (amd64/arm64)
  - `php7.3-3.0`, `php7.3-2`, `php7.3` - PHP 7.3 
- Previous stable versions v2 (amd64)
  - `php7.3-2.13`, `php7.3-2`, `php7.3` - PHP 7.3
  - `php7.4-2.13`, `php7.4-2`, `php7.4` - PHP 7.4
  - `php8.0-2.13`, `php8.0`, `php8.0` - PHP 8.0


## PHP

- php-fpm && php-cli
- xdebug v3
- composer v1 & v2
- drush (Drupal)
  - drush launcher with a fallback to a global drush 8
  - coder-8.x + phpcs
- drupal console launcher (Drupal)
- wp-cli (Wordpress)

This image uses the official `php-fpm` images from [Docker Hub](https://hub.docker.com/_/php/) as the base.
This means that PHP and all modules are installed from source. Extra modules have to be installed in the same
manner (installing them with `apt-get` won't work).

### Available PHP database drivers

- SQLite - via `sqlite3`, `pdo_sqlite`
- MySQL - via `mysqli`, `mysqlnd`, `pdo_mysql`
- PostgreSQL - via `pgsql`, `pdo_pgsql`
- MSSQL - via `sqlsrv` and `pdo_sqlsrv` (amd64 only)


### Using PHP Xdebug

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

[See docs](https://docs.docksal.io/tools/xdebug/) on using Xdebug for web and cli PHP debugging.


## NodeJS

- nvm
- node v14.17.3 (following NodeJS LTS release cycle)
- yarn

NodeJS is installed via `nvm` in the `docker` user's profile inside the image (`/home/docker/.nvm`).

If you need a different version of node, use `nvm` to install it, e.g., `nvm install 11.6.0`.
Then, use `nvm use 11.6.0` to use it in the current session or `nvm alias default 11.6.0` to use it by default.

## Python

This image comes with a system level installed Python v3.9.x from upstream Debian 11.

## Ruby

This image comes with a system level installed Ruby v2.7.x from upstream Debian 11.

## Notable console tools

- git with git-lfs
- curl, wget
- zip, unzip
- jq, yq
- mysql, pgsql, and sqlsrv cli clients
- imagemagick, ghostscript
- mc, nano, rsync
- mhsendmail
- cron

## Hosting provider tools

- `acli` for Acquia Cloud APIv2 ([Acquia](https://docs.acquia.com/acquia-cli/))
- `terminus` ([Pantheon](https://pantheon.io/features/terminus-command-line-interface))
- `platform` ([Platform.sh](https://docs.platform.sh/development/cli.html))

Also, see the [Secrets](#secrets) section below for more information on managing and using your hosting provider keys.


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
on the same host (e.g., in shared CI environments).

The value must be base64 encoded, i.e.:

```bash
cat /path/to/some_key_rsa | base64
```

`SECRET_ACQUIA_CLI_KEY` and `SECRET_ACQUIA_CLI_SECRET`

Credentials used to authenticate [Acquia CLI](https://github.com/acquia/cli) with Acquia Cloud APIv2.
Stored as `ACQUIA_CLI_KEY` and `ACQUIA_CLI_SECRET` environment variables inside `cli`.

Acquia CLI is installed and available globally in `cli` as `acli`.

`SECRET_TERMINUS_TOKEN`

Credentials used to authenticate [Terminus](https://pantheon.io/docs/terminus) with Pantheon.
Stored in `/home/docker/.terminus/` inside `cli`.

Terminus is installed and available globally in `cli` as `terminus`.

`SECRET_PLATFORMSH_CLI_TOKEN`

Credentials used to authenticate with the [Platform.sh CLI](https://github.com/platformsh/platformsh-cli) tool.
Stored in `/home/docker/.platform` inside `cli`.

Platform CLI is installed and available globally in `cli` as `platform`.

`WEB_KEEPALIVE`

Sets the delay in seconds between pings of the web container during execution `fin exec`. Setting this variable to non zero value prevents the project from stopping in cases of long `fin exec` and web container inactivity. Disabled by default (set to 0).

## Git configuration

When working with git from within the image, it will ask for the `user.email` and `user.name` set before you can commit.
These can be passed as environment variables and will be applied at the container startup.

```
GIT_USER_EMAIL="git@example.com"
GIT_USER_NAME="Docksal CLI"
```


<a name="ide"></a>
## Coder (Visual Studio Code web IDE)

[Coder](https://coder.com/) is a free, open-source web IDE.

VS Code Server is pre-installed along with GitLens and PHP Xdebug extensions.

### Configuration

`IDE_ENABLED` (default: 0)

Set to `1` to start the image in IDE mode. VS Code web UI will is listening on port `8080`.

`IDE_PASSWORD` (default: '')

Store your preferred password in this variable if you need to password protect the IDE environment.

[See docs](https://docs.docksal.io/tools/ide/) for instructions on using Coder in Docksal.

## Composer

Composer v1 and v2 are both installed in the container. v2 is set as the default version, but while not all
projects may be able to work with v2 quite yet, v1 is available by setting the `COMPOSER_DEFAULT_VERSION` variable to `1`.

Example:

```
services:
  cli:
    environment:
      - COMPOSER_DEFAULT_VERSION=1
```

The following Composer optimization packages are no longer relevant/compatible with Composer v2 and have been dropped:

- [hirak/prestissimo](https://github.com/hirak/prestissimo)
- [zaporylie/composer-drupal-optimizations](https://github.com/zaporylie/composer-drupal-optimizations)

To benefit from these optimizations with Composer v1, you would need to pin the image to an older version.
See Docksal [documentation](https://docs.docksal.io/service/cli/settings#composer) for more details.
