#!/usr/bin/env bash

binaries_amd64=\
'cat
convert
curl
dig
g++
ghostscript
git
git-lfs
gcc
jq
html2text
less
make
mc
more
mysql
nano
nslookup
ping
psql
pv
rsync
sudo
unzip
wget
yq
zip'

binaries_arm64=\
'cat
convert
curl
dig
g++
ghostscript
git
git-lfs
gcc
html2text
less
make
mc
more
mysql
nano
nslookup
ping
psql
pv
rsync
sudo
unzip
wget
yq
zip'

case "$(uname -m)" in
	x86_64) echo "${binaries_amd64}" ;;
	amd64) echo "${binaries_amd64}" ;;
	aarch64) echo "${binaries_arm64}" ;;
	arm64) echo "${binaries_arm64}" ;;
	* ) false;;
esac
