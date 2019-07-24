+++
Description = "How to Install Wordpress"
title = "How to Install Wordpress"
date = "2014-07-03T17:48:00+01:00"

+++
Because I have installed Wordpress for testing purposes way too often, i decided to write my setup down so I can reference it and others can benefit from the install.
The installation was tested with Ubuntu 14.04 LTS 64bit.

<!--more-->

Here are my steps to get a Wordpress VM up and running in Ubuntu:

* Get the Ubuntu ISO image from their download site [http://www.ubuntu.com/download/server](http://www.ubuntu.com/download/server)
* Install it in your favourite VM software using the defaults

I personally like to add the IP of the VM to the login dialog so i can spot the IP when booting the VM without logging in, and then use putty or something else to SSH into the machine.
To add the IP to the login screen we have to change the `/etc/issue` file. Because this is only a text file, we need to add the IP on boot to it. So add the following lines to your `/etc/rc.local` file (right above the `exit 0;` statement):

```bash
IP=$(/sbin/ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')
echo "eth0 IP: $IP" > /etc/issue
```

Now log in via SSH to the machine and execute the following commands:

```bash
sudo su
apt update
apt -qy install apache2 mariadb-server php5-mysql php5 libapache2-mod-php5 php5-mcrypt php5-gd unzip curl ed
```

Enter your MYSQL root PW during installation when prompted

```bash
/usr/bin/mysql_secure_installation
```

Enter your MYSQL root password again, select no do not change it and answer all other questions with `YES`.

```bash
cd /var/www/
wget http://wordpress.org/latest.zip
unzip latest.zip
rm latest.zip
cd wordpress/
mv wp-config-sample.php wp-config.php
# create DB user
mysql -u root -ppassword -e "CREATE DATABASE wordpress;"
mysql -u root -ppassword -e "CREATE USER wordpress@localhost;"
mysql -u root -ppassword -e "SET PASSWORD FOR wordpress@localhost=PASSWORD('wordpress');"
mysql -u root -ppassword -e "GRANT ALL PRIVILEGES ON wordpress.* TO wordpress@localhost;"
mysql -u root -ppassword -e "FLUSH PRIVILEGES;"
# configure Wordpress
sed -i -r "s/define\('DB_NAME', '[^']+'\);/define\('DB_NAME', 'wordpress'\);/g" wp-config.php
sed -i -r "s/define\('DB_USER', '[^']+'\);/define\('DB_USER', 'wordpress'\);/g" wp-config.php
sed -i -r "s/define\('DB_PASSWORD', '[^']+'\);/define\('DB_PASSWORD', 'wordpress'\);/g" wp-config.php
# add Salts
printf '%s\n' "g/put your unique phrase here/d" a "$(curl -sL https://api.wordpress.org/secret-key/1.1/salt/)" . w | ed -s wp-config.php
chown -R www-data:www-data /var/www
cd /etc/apache2/sites-available/
cp 000-default.conf 001-wordpress.conf
vim 001-wordpress.conf
```

set `DocumentRoot` to `/var/www/wordpress`

```bash
a2dissite 000-default # disable default site
a2ensite 001-wordpress # enable new wordpress site
# set file upload size to something bigger then 2MB
sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 20M/" /etc/php5/apache2/php.ini
service apache2 restart
```

If you want to disable automatic updates to have a stable testing machine, just add the following lines to your `wp-config.php` right before the line `/* That's all, stop editing! Happy blogging. */`.

```php
define( 'WP_AUTO_UPDATE_CORE', false );
define( 'AUTOMATIC_UPDATER_DISABLED', true );
```

If you also want to block all external internet traffic from your machine (ie when sitting behind a proxy) add the following line to `wp-config.php`:

```php
define( 'WP_HTTP_BLOCK_EXTERNAL', TRUE );
```

Now call the site via your browser, configure the last details and your blog is fully configured.
