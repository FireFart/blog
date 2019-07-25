#!/bin/bash
set -evx

echo removing old files...
rm -rf public/*
echo generating new files...
../hugo
echo removing .DS_Store files...
find . -name .DS_Store -exec rm -f {} \;
echo checking links ...
#bundle exec htmlproofer ./public
echo syncing stuff...
rsync --progress -arzvh -e "ssh -p 9988" --delete-before --delete public/ root@firefart.at:/var/www/blog/
echo chmodding all the things...
ssh -p 9988 root@firefart.at "chown -R www-data:www-data /var/www/blog/"
echo finished
