#!/usr/bin/env bash

php_modules_amd64=\
'[PHP Modules]
apcu
bcmath
blackfire
bz2
calendar
Core
ctype
curl
date
dom
exif
fileinfo
filter
ftp
gd
gettext
gnupg
hash
iconv
imagick
imap
intl
json
ldap
libxml
mbstring
memcached
mysqli
mysqlnd
openssl
pcntl
pcre
PDO
pdo_mysql
pdo_pgsql
pdo_sqlite
pdo_sqlsrv
pgsql
Phar
posix
readline
redis
Reflection
session
SimpleXML
soap
sockets
sodium
SPL
sqlite3
sqlsrv
ssh2
standard
sysvsem
tokenizer
xml
xmlreader
xmlwriter
xsl
Zend OPcache
zip
zlib

[Zend Modules]
Zend OPcache
blackfire
'

php_modules_arm64=\
'[PHP Modules]
apcu
bcmath
blackfire
bz2
calendar
Core
ctype
curl
date
dom
exif
fileinfo
filter
ftp
gd
gettext
gnupg
hash
iconv
imagick
imap
intl
json
ldap
libxml
mbstring
memcached
mysqli
mysqlnd
openssl
pcntl
pcre
PDO
pdo_mysql
pdo_pgsql
pdo_sqlite
pgsql
Phar
posix
readline
redis
Reflection
session
SimpleXML
soap
sockets
sodium
SPL
sqlite3
ssh2
standard
sysvsem
tokenizer
xml
xmlreader
xmlwriter
xsl
Zend OPcache
zip
zlib

[Zend Modules]
Zend OPcache
blackfire
'

case "$(uname -m)" in
	x86_64) echo "${php_modules_amd64}" ;;
	amd64) echo "${php_modules_amd64}" ;;
	aarch64) echo "${php_modules_arm64}" ;;
	arm64) echo "${php_modules_arm64}" ;;
	* ) false;;
esac
