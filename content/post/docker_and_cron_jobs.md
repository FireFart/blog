+++
Description = "How to run cron jobs with docker"
title = "How to run cron jobs with docker"
date = "2017-11-06T00:30:00+01:00"
metakeys = ["cron", "cron jobs", "docker", "docker-compose"]
+++

Lately I came across the problem of running cron jobs in a docker based environment when we migrated [wpvulndb.com](https://wpvulndb.com) to a docker based install.
So how should we execute cron jobs when the application is running with docker or docker-compose?

<!--more-->

You have two choices of running cron jobs with docker:

- Execute them on the host system with `docker exec` or `docker run` in your application container
- Create a separate cron enabled docker container

The first method may be the simplest for your needs. Just edit the crontab of your host system and execute single tasks in your application container. The jobs need to run as root on the host system or the user has to be to be in the `docker` group - which is basically the same as running as root.

For example this was one of our cron jobs executed from the host inside the application container using `docker-compose`:

```bash
/bin/bash -c 'cd /opt/wpvulndb/ && docker-compose -f docker-compose.yml -f docker-compose.staging.yml -f docker-compose.prod.yml run -T --name cron_sitemap --rm cron bundle exec rake -s sitemap:refresh'"
```

The `cron` container in this case was just another instance of the main application image. We could also execute `docker-compose exec` (or `docker exec`) to run the command in the main application container but we created a separate container so we do not interrupt any processes inside the main container.

But there is one simple problem with this setup:

Normally errors are written to stdout and the cron daemon keeps sending every output from the jobs to the email address specified in the `MAILTO` environment variable. Sadly `docker-compose` does NOT support a quiet/silent flag so the starting messages of the single containers are always printed out and interpreted as errors by the cron daemon.

```text
Starting wpvulndb_redis
Starting wpvulndb_db
Starting wpvulndb_sidekiq
Starting wpvulndb_web
```

This ended up with a lot of emails for every cron job although we are only interested in errors.

So my choice for running the cron jobs was directly inside an container. There are some blog posts and stack overflow comments about this topic out there but either they are really old or miss some important details.

One thing you find a lot on the internet is something like: `cron && tail -f /var/log/cron.log` as the main docker command - This is bad

This command would execute cron and tails the log file so it will be visible with `docker logs`. But there is an problem with this:
If the cron daemon fails after some time the docker container will continue to run because it tails the log file and does not monitor the cron process as it should be. The crash of crond will be undetected. So from outside the container it looks like your cron jobs are running - but they don't. Only the tail of the log file is running, beeing monitored by docker and reported as UP.

You should try to only have one main process running inside the container so the docker engine can monitor the health of your containers and restart them if needed or notify you.

So how to run the cron daemon correctly?

Normally all docker base images are stripped down with no running processes (like the cron daemon) because of the one process concept mentioned above. In the alpine base image there is a cron daemon installed but you need to run it on your own.

The following Dockerfile creates a separate user and copies a new crontab file to the machine. When this container is run all logs will be available via `docker logs` or `docker-compose logs`.

```docker
FROM alpine:latest
LABEL maintainer="Christian Mehlmauer <FireFart@gmail.com>"

ENV APP_USER appuser

RUN adduser -g "App User" -D $APP_USER

COPY crontab /var/spool/cron/crontabs/$APP_USER
RUN chmod 0600 /var/spool/cron/crontabs/$APP_USER

ENTRYPOINT "crond"

CMD ["-f", "-d", "8"]
```

`crontab` file:

```text
0 2 * * * /bin/date
```

The cron daemon parameters in use are:

- `-f`: The cron daemon will run in the foreground. This way docker is able to monitor the process.
- `-d 8`: This instructs the daemon to log to stderr with the default log level 8. Without this flag messages are only written to syslog and you can't access them via the `logs` command.

Using this method of cron involves monitoring the logs of the container using some kind of monitoring like a log management or send the output from the jobs itself as email.

The cron files on alpine Linux work like this:

**/var/spool/cron/crontabs/root**

This file contains every cronjob that should be executed by the root user.

If you have a look at the file it contains the following lines per default:

```text
# do daily/weekly/monthly maintenance
# min   hour   day   month   weekday   command
*/15    *   *   *   *   run-parts /etc/periodic/15min
0   *   *   *   *   run-parts /etc/periodic/hourly
0   2   *   *   *   run-parts /etc/periodic/daily
0   3   *   *   6   run-parts /etc/periodic/weekly
0   5   1   *   *   run-parts /etc/periodic/monthly
```

This means you can also put your executable scripts inside one of these folders and they will be run by root automatically. If you put a bash script into `/etc/periodic/15min` and make it executable the cron daemon will execute it every 15 minutes.

If you want your jobs to be executed at different times just add a line to this file using cron syntax.

**ATTENTION**: You MUST NOT use an extension on the files placed inside the `periodic` folders. If you place a shell script inside just omit the extension and make sure it starts with the correct shebang `#!/bin/sh`. See here for details: https://wiki.alpinelinux.org/wiki/Alpine_Linux:FAQ#My_cron_jobs_don.27t_run.3F

**/var/spool/cron/crontabs/APPUSER**

This file contains cronjobs that should be executed by the user matching the file name. This is handy if you want to run cron jobs as a different user. It's a good habit to run jobs as a separate user if the job does not require root privileges to reduce the attack surface.

You can also integrate the steps mentioned above inside your main Dockerfile (if it's based on an alpine based image) and change the entrypoint and command to the cron commands if you need access to the main application for the cron jobs.

For example our `docker-compose.yml` file uses the following snippet on the main Dockerfile to use it as a cron container with a different entrypoint (the `user: root` is important as the cron daemon needs to run as root):

```text
entrypoint: ""
user: root
command: crond -f -d 8
```

Also be sure to mount your local timezone file into the container so the time inside matches your host system time and the jobs get executed at the correct time.

In `docker-compose` use the following:

```yml
volumes:
    - /etc/localtime:/etc/localtime:ro
```

In docker use the following command line option:

```text
-v /etc/localtime:/etc/localtime:ro
```

I hope this post gave a good overview on how to design your docker setup to also run cron jobs.
