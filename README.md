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
  - drupal console launcher
  - wp-cli
- ruby
  - ruby
  - gem
  - bundler
- nodejs
  - nvm
  - nodejs (via nvm)
  - npm, yarn
- python

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
