# CLI Docker image for Drupal

Based on Debian 7.0 "Wheezy" (debian:wheezy)

## Includes

- php
  - php-fpm && php-cli 5.6.x
  - composer 1.0-dev
  - drush 6,7,8
    - registry_rebuild
    - coder-8.x + phpcs
  - drupal console 0.9.7
- ruby
  - ruby 1.9.3
  - gem 1.8.23
  - bundler 1.10.6
- nodejs
  - nvm 0.29.0
  - nodejs 4.2.2 (via nvm)
    - npm 3.4.0
    - bower 1.6.5
- python 2.7.3

Other notable tools:

- git
- curl/wget
- zip/unzip
- mysql-client
- imagemagick
- ping
- mc


## License

The MIT License (MIT)

Copyright (c) 2015 blinkreaction

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
