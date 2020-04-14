+++
Description = "Using the MySQL/MariaDB Service with Github Actions"
title = "Using the MySQL Service with Github Actions"
date = "2019-11-27T8:00:00+01:00"
metakeys = ["github", "github actions", "mysql", "mariadb"]

+++

With the newly introduced [Github Actions](https://help.github.com/en/actions/automating-your-workflow-with-github-actions) it's now possible to run your unit tests and other automation tasks automatically on Githubs infrastructure based on events. This is a short blog post describing how to use the MySQL / MariaDB services with Github Actions.

<!--more-->

The Ubuntu image already contains a preconfigured MySQL server but if you want to use a specific or newer version or even a MariaDB server you need to use a service. A service in Github Actions is just a docker container running a specific image and exposing it's ports to localhost. You can also install the services you need via `apt-get` but using Docker might be easier in this case.

You need to be careful with this setup because if you use the default port your app or tests will connect to the local mysql server instead of the docker one. To ensure the app is using the correct database be sure to use the `${{ job.services.SERVICENAME.ports[3306] }}` variable and pass it to your config. As MySQL in Docker can take up to a few minutes to be available due to the startup scripts being run you need to wait until the server becomes ready or it will not accept connections and the following steps may fail due to the missing database connection.

The following YML code can be used as an example for such an action.

In the `services` section we define which database docker image to start (`mariadb:latest` in this case) and which ports are exposed. The Environment variables passed to it are used by the docker image to create the initial database and specify the users. See [https://hub.docker.com/\_/mariadb/](https://hub.docker.com/_/mariadb/) or [https://hub.docker.com/\_/mysql](https://hub.docker.com/_/mysql) for more details. The `options` specified are passed to docker for it's internal healthcheck. This command ensures that the database is reachable during the tests and docker will auto restart the container if the command specified fails for `health-retries` times.
In the `Verify MariaDB connection` section a simple `mysqladmin ping` is executed to ensure the database is fully up and running before continuing with the tests. As the port from the container is mapped to a random port on the host we also need to grab it via the exposed variable `${{ job.services.mariadb.ports[3306] }}` and pass it via an environment variable to the command.

```yml
name: Tests

on: [push]

jobs:
  build:
    runs-on: ubuntu-latest

    services:
      mariadb:
        image: mariadb:latest
        ports:
          - 3306
        env:
          MYSQL_USER: user
          MYSQL_PASSWORD: password
          MYSQL_DATABASE: test
          MYSQL_ROOT_PASSWORD: password
        options: --health-cmd="mysqladmin ping" --health-interval=5s --health-timeout=2s --health-retries=3

    steps:
      - uses: actions/checkout@v1

      - name: Verify MariaDB connection
        env:
          PORT: ${{ job.services.mariadb.ports[3306] }}
        run: |
          while ! mysqladmin ping -h"127.0.0.1" -P"$PORT" --silent; do
            sleep 1
          done

      - name: Test
        run: |
          your tests
```
