+++
Description = "Turning Piwik Superuser Credentials into Remote Code Execution"
title = "Turning Piwik Superuser Credentials into Remote Code Execution"
date = "2017-02-07T23:30:00+01:00"
image = "/img/misc/hacker.jpg"
+++

On a recent pentest I got root access to a MySQL database hosting a PHP web application and also an instance of [Piwik](https://piwik.org/). I was able to extract the credentials from the database and crack them really fast because they were only hashed using MD5. It looks like Piwik introduced stronger hashes in Piwik 3 but luckily this target is still running version 2.

**Edit**:  *Piwik now disabled custom plugin uploads by default in 3.0.3 ([Changelog](https://piwik.org/changelog/piwik-3-0-3/)). You have to manually enable it in the config (See [FAQ](https://piwik.org/faq/plugins/faq_21/)) so this removes a lot attack surface from existing installs.*

<!--more-->

So what to do with the passwords? Only changing some Piwik parameters or reading visitor stats is not really exciting so I took a look around in the superuser dashboard and found something interesting: Piwik supports plugins.

Piwik has 3 levels of access: view, admin and superuser. If you have an user with superuser access (the first user from the database) you can install new plugins to the server if the web root is writeable by the web server.

Finding some tutorials on the internet for writing Piwik plugins is hard (most of them are about writing plugins for Piwik 1) so I had to download several plugins and do a copy paste to generate my own plugin.

The plugin generally consist of a `plugin.json` containing some metadata showed in the Marketplace and a main PHP file named after the plugin containing the code.

You can write a super fancy plugin adding new menus to the dashboard and showing some nice remote code execution pages with templates but that's way too much work. Luckily there is a `install` method which will be called when the plugin is activated. So this looks like a good place to put a payload in.

If we write a plugin called **pwned** the folder structure would be:
```
pwned/
pwned/pwned.php
pwned/plugin.json
```

And the file content:

**pwned.php**
```php
<?php
namespace Piwik\Plugins\pwned;
class pwned extends \Piwik\Plugin {
  public function install()
  {
    PHP_PAYLOAD
  }
}
```

**plugin.json**
```json
{
  "name": "pwned",
  "description": "DESCRIPTION",
  "version": "1.0",
  "theme": false
}
```

You can zip those files together and upload it from the Marketplace site in the dashboard as superuser. After you activate the plugin the payload will be executed effectively turning the superuser credentials into remote code execution.

As I like to automate the boring stuff I also wrote a Metasploit module to easily pwn Piwik installations. Because the payload fires on install and the files are automatically removed once the session is opened the plugin will not show up in the Marketplace and thus be really stealthy.

You can find the Metasploit module here: https://github.com/rapid7/metasploit-framework/pull/7917
