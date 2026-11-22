# Docker Exment

This is a repository for building a Docker environment (nginx + PHP-FPM + database) to run [Exment](https://github.com/exceedone/exment) on top of [exment-boilerplate](https://github.com/exceedone/exment-boilerplate).
It supports MySQL, MariaDB and SQL Server.

It is also used by the automated tests (CI) of Exment.

## Requirements

- Docker with the Compose plugin (`docker compose`)
- `make`
- `git`

## Getting started

1. Clone this repository.

    ```bash
    $ git clone https://github.com/exceedone/docker-exment.git
    $ cd docker-exment
    ```

2. Clone [exment-boilerplate](https://github.com/exceedone/exment-boilerplate) into the `exment-boilerplate` folder inside this repository.
   The containers mount `./exment-boilerplate` as the Laravel application, so the folder name must be exactly `exment-boilerplate`.

    ```bash
    $ git clone https://github.com/exceedone/exment-boilerplate.git exment-boilerplate
    ```

3. If needed, edit `.env` in this repository (ports, PHP version, database passwords, etc.).
   Please change the default passwords when the environment is reachable from other machines.

4. Build the environment for your database (first time only). See the sections below.

5. Open http://localhost/admin in your browser and follow the Exment setup screen.
   (If you changed `EXMENT_DOCKER_HTTP_PORTS` in `.env`, use that port.)

### MySQL

```bash
# first time (recreates the containers, runs composer install, copies .env.mysql to .env, generates keys)
$ make mysql-init

# from the second time
$ make mysql-up
```

### MariaDB

```bash
# first time
$ make mariadb-init

# from the second time
$ make mariadb-up
```

### SQL Server

```bash
# first time (also creates the database)
$ make sqlsrv-init

# from the second time
$ make sqlsrv-up
```

The SQL Server `sa` password is `EXMENT_DOCKER_SQLSRV_ROOT_PASSWORD` in `.env`. It must be a complex password, and it must match `DB_PASSWORD` in `exment-boilerplate/.env.sqlsrv`.

### Previews of Office files (optional)

The file server of Exment can show Word, Excel and PowerPoint files as PDF. The conversion runs in a container of its own (`office`: [Gotenberg](https://gotenberg.dev/) with LibreOffice only), not in the PHP container.

1. Add `-f docker-compose.office.yml` when you start the containers:

    ```bash
    $ docker compose -f docker-compose.yml -f docker-compose.mysql.yml -f docker-compose.office.yml up -d
    ```

2. Add this line to `exment-boilerplate/.env`:

    ```
    EXMENT_FILE_SERVER_SOFFICE_URL=http://office:3000
    ```

- The converter opens no port to the outside. Only the PHP container reaches it, on an inner network that cannot reach the Internet, the cloud metadata or the database.
- Its disk is read only and it works in memory; it keeps no file after a conversion.
- Its limits are in `.env` (`EXMENT_DOCKER_OFFICE_*`): 1 CPU, 1 GB of memory, 120 seconds for a conversion, a queue of 10. When the queue is full it answers 429 and Exment asks again a little later.
- Exment converts a file the first time its preview is opened (not when it is uploaded) and keeps the PDF; two people opening it at once start one conversion.
- The image is about 1.5 GB.

## Other commands

| Command | Description |
| --- | --- |
| `make down` | Stop and remove the containers |
| `make ps` | Show the containers |
| `make logs` | Show the logs |
| `make logs-watch` | Follow the logs |
| `make php` | Open a shell in the PHP container |
| `make destroy` | Remove the containers, images and volumes (**the database data is deleted**) |

## Running the Exment tests

See [ExmentTest.md](ExmentTest.md) (Japanese).
