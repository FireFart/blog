#!/bin/bash
set -e

printf "\033[0;32mDeploying updates to GitHub...\033[0m\n"
hugo
cd public
git add .
msg="rebuilding site $(date)"
if [ -n "$*" ]; then
	msg="$*"
fi
git commit -m "$msg"
git push origin master
# echo checking links ...
#bundle exec htmlproofer ./public
#echo syncing stuff...
#rsync --progress -arzvh -e "ssh -p 9988" --delete-before --delete public/ root@firefart.at:/var/www/blog/
#echo chmodding all the things...
#ssh -p 9988 root@firefart.at "chown -R www-data:www-data /var/www/blog/"
#echo finished
