# CLI Docker image for Docksal

This image is focused on console tools necessary to develop LAMP stack applications (namely Drupal and WordPress).

This image(s) is part of the [Docksal](http://docksal.io) image library.

## Versions

- `docksal/cli:stable` - PHP 5.6
- `docksal/cli:php7` - PHP 7.0

## Includes

- php
  - php-fpm && php-cli 5.6.x / 7.0.x
  - xdebug
  - composer
  - drush (6,7,8)
    - registry_rebuild
    - coder-8.x + phpcs
  - drupal console
  - wp-cli
- ruby
  - ruby
  - gem
  - bundler
- nodejs
  - nvm
  - nodejs (via nvm)
    - npm
    - bower
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
