# CLI Docker image for Docksal

This image is focused on console tools necessary to develop LAMP stack applications (namely Drupal and WordPress).

This image(s) is part of the [Docksal](http://docksal.io) image library.


## Versions and image tag naming convention

- Stable versions
  - `<version>-php7`, `php7`, `latest` - PHP 7.0
  - `<version>-php5`, `php5` - PHP 5.6
- Development versions
  - `edge-php7` - PHP 7.0
  - `edge-php5` - PHP 5.6

Examples:

- `docksal/cli:1.2-php7` - a specific stable image version with PHP7
- `docksal/cli:php5` - the latest stable image version with PHP5


## Includes

- php
  - php-fpm && php-cli 5.6.x / 7.0.x
  - xdebug
  - composer
  - drush (6,7,8)
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
