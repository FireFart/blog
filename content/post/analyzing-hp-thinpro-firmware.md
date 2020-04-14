+++
Description = "Analyzing HP Thinpro Firmware"
date = "2013-11-13T17:44:00+01:00"
title = "Analyzing HP Thinpro Firmware"
+++

Today I got my hands on a [HP t510 Thinclient](http://www8.hp.com/us/en/campaigns/thin-client-solutions/t510.html) and wanted to analyze the OS and running services (apparently it's running Ubuntu 10.04.4 LTS).
Here is my solution to run the Firmware in a VMware Infrastructure, or simply mount the image for browsing.

<!--more-->

First you need to download the ThinPro Firmware for your Thinclient model from HP's Downloadcenter. Here is the link for the T510:

[http://h20000.www2.hp.com/bizsupport/TechSupport/SoftwareDescription.jsp?lang=en&amp;cc=us&amp;prodTypeId=12454&amp;prodSeriesId=5226831&amp;prodNameId=5226832&amp;swEnvOID=4030&amp;swLang=13&amp;mode=2&amp;taskId=135&amp;swItem=vc-117698-1](http://h20000.www2.hp.com/bizsupport/TechSupport/SoftwareDescription.jsp?lang=en&cc=us&prodTypeId=12454&prodSeriesId=5226831&prodNameId=5226832&swEnvOID=4030&swLang=13&mode=2&taskId=135&swItem=vc-117698-1)

After you finished the download you will get an exe containing the firmware. Run this file under Windows, select the Button named "Image" and save the extracted image.

![Extract](/img/thinclient/thinclient_extract.png "Extract")

This will give you a gz image. Transfer this image to your favorite linux box (I used kali) und run gunzip to unzip it

```bash
gunzip T6X43101.dd.gz
```

Now you have a .dd file, which is a raw ext3 disk image created with the dd command.

```text
T6X43101.dd: x86 boot sector; GRand Unified Bootloader, stage1 version 0x3, 1st sector stage2 0x1380c5; partition 1: ID=0x83, active, starthead 1, startsector 63, 2001825 sectors, code offset 0x48
```

Here is the binwalk output from this file

```text
DECIMAL         HEX             DESCRIPTION
-------------------------------------------------------------------------------------------------------------------
32256           0x7E00          Linux EXT filesystem, rev 1.0 ext3 filesystem data, UUID=c0cba688-cc23-404f-a7fb-d67fde13de13, volume name "ROOT"
1606144         0x188200        Squashfs filesystem, little endian, version 4.0, compression: gzip, size: 462368156 bytes,  33965 inodes, blocksize: 131072 bytes, created: Thu Mar 28 01:57:34 2013
644937077       0x2670F575      MPFS (Microchip) filesystem, version 61.121, 17162 file entries
644937095       0x2670F587      MPFS (Microchip) filesystem, version 95.77, 21839 file entries
645012614       0x26721C86      MPFS (Microchip) filesystem, version 61.121, 17162 file entries
645012629       0x26721C95      MPFS (Microchip) filesystem, version 95.80, 21327 file entries
645028352       0x26725A00      gzip compressed data, from Unix, last modified: Thu Mar 28 01:56:23 2013
653039724       0x26EC986C      gzip compressed data, from Unix, last modified: Fri Jul 29 23:17:55 2011, max compression
657147869       0x272B47DD      ELF (NetBSD)
657155473       0x272B6591      ELF
679509504       0x28807E00      Linux EXT filesystem, rev 1.0 ext3 filesystem data, UUID=c0cba688-cc23-404f-a7fb-d67fde13de13, volume name "ROOT"
```

To convert this image to a VMware Harddisk you first need to install the package **_qemu_** (if you only want to browse this image, scroll down a bit).

To start the conversion run the following command:

```text
qemu-img convert -f raw -O vmdk T6X43101.dd thinpro.vmdk
```

Next create an empty Virtual Machine, select existing Harddisk and use the converted thinpro.vmdk image. If you get a prompt to convert this image to a newer version of VMware, select yes.

Now you can boot and configure your very own "Thinclient" inside a VM :)

![VM](/img/thinclient/thinclient_vm.png "VM")

If you just need to browse the image contents, run parted on the .dd image to get the offset (User input is bold) or just use the offset from the binwalk output above.

```text
parted T6X43101.dd
GNU Parted 2.3
Using /media/psf/ThinClient/T6X43101.dd
Welcome to GNU Parted! Type 'help' to view a list of commands.
(parted) unit
Unit?  [compact]? B
(parted) print
Model:  (file)
Disk /media/psf/ThinClient/T6X43101.dd: 1024966656B
Sector size (logical/physical): 512B/512B
Partition Table: msdos
Number  Start   End          Size         Type     File system  Flags
1      32256B  1024966655B  1024934400B  primary  ext3         boot
(parted) quit
```

Now mount the image with the correct offset

```bash
mkdir /media/thinclient
mount -o loop,ro,offset=32256 T6X43101.dd /media/thinclient/
```

This will mount the dd image readonly and you will get some kernel images and the filesystem as a squashfs file. Install [firmware-mod-kit](https://code.google.com/p/firmware-mod-kit/) on your linux box so you get the tools needed to extract the filesystem.

```bash
/root/firmware-mod-kit/unsquashfs_all.sh /media/thinclient/filesystem.squash extract
```

This will extract the harddisk content to the folder extract.

```bash
root@kali:/media/psf/ThinClient/extract# ls -alh
total 0
drwxr-xr-x 1 root root  646 May 22 21:43 .
drwxr-xr-x 1 root root  442 May 23 09:58 ..
drwxr-xr-x 1 root root 3.5K Mar 28 01:55 bin
drwxr-xr-x 1 root root  136 Mar 28 01:50 debootstrap
drwxr-xr-x 1 root root  136 Mar 28 01:50 dev
drwxr-xr-x 1 root root  102 Mar 28 01:56 .flash
-rw-r--r-- 1 root root    2 Mar 28 01:56 fonts.dir
drwxr-xr-x 1 root root 3.3K May 22 21:46 lib
drwxr-xr-x 1 root root  170 May 22 21:46 opt
drwxr-xr-x 1 root root   68 Feb  3  2012 proc
drwxr-xr-x 1 root root 3.9K Mar 28 01:55 sbin
drwxr-xr-x 1 root root   68 Dec  5  2009 selinux
drwxr-xr-x 1 root root   68 Mar 28 01:50 srv
drwxr-xr-x 1 root root   68 Jan 20  2012 sys
drwxr-xr-x 1 root root   68 Mar 28 01:56 tmp
drwxr-xr-x 1 root root  340 May 22 21:46 usr
drwxr-xr-x 1 root root  306 May 22 21:46 var
drwxr-xr-x 1 root root  340 May 22 21:43 writable
```

Happy analyzing :)
