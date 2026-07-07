# cs143 Postgres image

A ready-to-use PostgreSQL container for CS143. It's the official Postgres image
plus `bash`, `psql`, and `wget`, and it's built for both Intel/AMD and Apple
Silicon / ARM machines (`linux/amd64` and `linux/arm64`).

On first start it creates:

- a superuser **`cs143`** with password **`cs143`**
- a database **`cs143`** owned by `cs143`

`cs143` is a superuser, so it can create and drop schemas and tables, import
data, etc. without any extra setup.

| | |
|---|---|
| **Host / port** | `localhost` : `5432` |
| **Database** | `cs143` |
| **Username** | `cs143` |
| **Password** | `cs143` |

---

## 1. Install Docker

You only need **Docker** (Docker Desktop on Mac/Windows, or Docker Engine on
Linux). Pick your operating system below.

### macOS

1. Find your chip: click the  Apple menu → **About This Mac**. It says either
   **Apple M1/M2/M3…** (Apple Silicon) or **Intel**.
2. Download **Docker Desktop** for your chip:
   <https://www.docker.com/products/docker-desktop/>
   (choose "Apple Silicon" or "Intel Chip" to match step 1).
3. Open the downloaded `Docker.dmg` and drag **Docker** into **Applications**.
4. Launch **Docker** from Applications and accept the prompts. When the whale
   icon 🐳 in the menu bar stops animating, Docker is ready.
5. Verify in **Terminal**:
   ```bash
   docker run --rm hello-world
   ```
   You should see "Hello from Docker!".

> Homebrew alternative: `brew install --cask docker`, then launch Docker Desktop
> once so it can finish setup.

### Windows

1. Requirements: Windows 10/11 64-bit. Docker Desktop uses **WSL 2** (the Windows
   Subsystem for Linux).
2. Enable WSL 2 — open **PowerShell as Administrator** and run:
   ```powershell
   wsl --install
   ```
   Reboot if prompted.
3. Download and run the **Docker Desktop Installer** from
   <https://www.docker.com/products/docker-desktop/>. Keep "Use WSL 2 instead of
   Hyper-V" checked.
4. Start **Docker Desktop** from the Start menu and wait for it to say
   "Engine running".
5. Verify in **PowerShell** (or Windows Terminal):
   ```powershell
   docker run --rm hello-world
   ```

> Run the `docker` commands in this README from **PowerShell**, **Windows
> Terminal**, or a **WSL/Ubuntu** shell.

### Linux

Install **Docker Engine** using Docker's convenience script (works on Ubuntu,
Debian, Fedora, and more):

```bash
curl -fsSL https://get.docker.com | sudo sh
```

Then let your user run Docker without `sudo` (log out/in afterward, or run
`newgrp docker`):

```bash
sudo usermod -aG docker "$USER"
```

Verify:

```bash
docker run --rm hello-world
```

For distro-specific package instructions instead of the script, see
<https://docs.docker.com/engine/install/>.

---

## 2. Get the image

**If your instructor published it to a registry** (recommended), just pull it —
Docker automatically fetches the right build for your CPU:

```bash
docker pull YOUR_REGISTRY/cs143:latest
```

> Ask your instructor for the exact image name to put in place of
> `YOUR_REGISTRY/cs143:latest`. Everywhere below that shows
> `cs143:latest`, use that name.

**If you were given an image file** (`cs143.tar`):

```bash
docker load -i cs143.tar
```

**To build it yourself** from this folder, see [For instructors](#for-instructors).

---

## Easiest path: the `shell.sh` helper

This repo includes **`shell.sh`**, a single script that manages the whole
container lifecycle so you don't have to remember the individual `docker`
commands. It creates the container the first time, starts it if it's stopped,
waits until Postgres is actually ready, and drops you into a shell.

### Download the script

Download `shell.sh` from the **instructor-provided link** into a folder you'll
work from, then make it executable:

```bash
# replace INSTRUCTOR_PROVIDED_LINK with the link your instructor gives you
wget -O shell.sh INSTRUCTOR_PROVIDED_LINK      # or: curl -L -o shell.sh INSTRUCTOR_PROVIDED_LINK
chmod +x shell.sh
```

> On **Windows**, download and run `shell.sh` from a **WSL 2 / Ubuntu** terminal
> (or Git Bash) — see [Windows & Docker Desktop notes](#windows--docker-desktop-notes).

### Use the script

```bash
./shell.sh          # ensure the container is running, then open a bash shell in it
```

Inside that shell, Postgres is already running in the background, so you can
just:

```bash
psql -U cs143 -d cs143
```

Typing `exit` leaves the shell but **leaves Postgres running**. All commands:

| Command | What it does |
|---------|--------------|
| `./shell.sh` or `./shell.sh shell` | Ensure it's running, then open a **bash** shell inside it |
| `./shell.sh psql` | Ensure it's running, then open **psql** directly |
| `./shell.sh up` | Create/start it in the background, don't attach |
| `./shell.sh stop` | Stop it (container + data preserved) |
| `./shell.sh restart` | Stop then start |
| `./shell.sh status` | Show whether it exists / is running |
| `./shell.sh logs` | Follow the Postgres logs (`Ctrl-C` to detach) |
| `./shell.sh rm` | Remove the container (the `cs143-data` volume is **kept**) |
| `./shell.sh help` | Show usage |

**Nothing to set up first** — you don't create any directories, paths, or
permissions. The script stores data in a Docker-managed named volume
(`cs143-data`) that Docker creates automatically, and Postgres manages ownership
inside the container. You only need Docker installed (section 1) and the image
available (section 2). Make sure the script is executable once:

```bash
chmod +x shell.sh
```

You can override defaults with environment variables:

| Var | Default | Meaning |
|-----|---------|---------|
| `NAME` | `cs143` | Container name |
| `IMAGE` | `cs143:latest` | Image to run |
| `PORT` | `5432` | Host port mapped to Postgres |
| `VOLUME` | `cs143-data` | Named data volume (set empty to store data only in the container) |

```bash
PORT=5433 ./shell.sh up      # e.g. if 5432 is already in use
```

### Windows & Docker Desktop notes

Everything **inside** the container is identical on every platform — it's the
same Linux Postgres image on Mac, Windows, and Linux, so `psql`, `wget`, data
loading, ports, and credentials all behave the same. Only a few **host-side**
things differ:

- **`./shell.sh` needs a bash shell.** On Windows, PowerShell can't run
  `./shell.sh` directly. Use the **Ubuntu/WSL 2** terminal (recommended — Docker
  Desktop's WSL integration provides `docker` there) and run `./shell.sh`, or use
  **Git Bash** and run `bash shell.sh`. If you'd rather stay in PowerShell, use
  the manual `docker` commands in the numbered sections below instead — they work
  everywhere.
- **Keep the script's line endings as LF.** If `shell.sh` gets Windows (CRLF)
  line endings, it fails with `bad interpreter: /usr/bin/env bash^M`. Editing it
  in WSL, or `git config core.autocrlf input`, avoids this.
- **The data volume isn't a browsable folder on Docker Desktop.** On Docker
  Desktop (Mac/Windows, and Docker Desktop on Linux) the `cs143-data` volume
  lives inside Docker's Linux VM, not at a path you can open in Finder/Explorer.
  Only native Linux Docker Engine exposes it at `/var/lib/docker/volumes/…`.
  Either way you manage it the same way, via `docker volume` and `psql`.

Connecting to `localhost:5432` from your host works the same on all platforms —
Docker Desktop publishes the port to your machine's localhost automatically.

The rest of this README explains the equivalent **manual** `docker` commands, in
case you prefer to run them yourself or need to understand what the script does.

---

## 3. Start the container

```bash
docker run -d --name cs143 -p 5432:5432 \
  -v cs143-data:/var/lib/postgresql/data \
  cs143:latest
```

What each part means:

- `-d` — run in the background (detached).
- `--name cs143` — give the container a friendly name so you can manage it.
- `-p 5432:5432` — publish Postgres so you can reach it from your machine
  (`host-port:container-port`). This is what makes it accessible **outside** the
  container.
- `-v cs143-data:/var/lib/postgresql/data` — store the data in a named volume so
  it **survives** stopping/removing the container. Drop this if you don't care
  about keeping data.

The first start takes a few seconds while it initializes the `cs143` database.

---

## 4. Connect to Postgres

**From the shell inside the container** (nothing else to install):

```bash
docker exec -it cs143 psql -U cs143 -d cs143
```

**From your own machine** (the host), if you have `psql` installed locally:

```bash
PGPASSWORD=cs143 psql -h localhost -p 5432 -U cs143 -d cs143
```

**From a GUI** (pgAdmin, DBeaver, TablePlus, …) or your course code, use:

```
host=localhost  port=5432  database=cs143  user=cs143  password=cs143
```

Quick "is it working?" check:

```bash
docker exec -it cs143 psql -U cs143 -d cs143 -c "select version();"
```

### Accessing it from another machine (e.g. a classmate on the LAN)

The server already listens on all interfaces and requires the `cs143` password
for network connections, so nothing extra is needed on the server side — the
other machine connects to **your host's IP** on port 5432:

```bash
psql -h YOUR_HOST_IP -p 5432 -U cs143 -d cs143
```

Notes:

- Make sure your host firewall allows inbound TCP **5432**.
- `-p 5432:5432` listens on all interfaces. To restrict Postgres to your own
  machine only, start it with `-p 127.0.0.1:5432:5432` instead.
- If port 5432 is already taken on your machine, map another one, e.g.
  `-p 5433:5432`, and then connect with `-p 5433`.

---

## 5. Load data into the database

You don't need any shared folders or host setup to get data in — the image
ships with `wget`, so you download the data **inside the container** straight
into Postgres. The general recipe is: open a shell, fetch the file, import it.

```bash
./shell.sh            # opens a bash shell inside the running container
```

**Loading a SQL dump** (`.sql` — the most common case; it contains the
`CREATE TABLE` / `INSERT` statements):

```bash
# inside the container's shell
wget https://example.com/path/to/data.sql        # download it
psql -U cs143 -d cs143 -f data.sql               # run it into the database
```

**Loading a CSV** into a table you define:

```bash
# inside the container's shell
wget https://example.com/path/to/people.csv

psql -U cs143 -d cs143 <<'SQL'
CREATE TABLE people (id int, name text, age int);
\copy people FROM 'people.csv' WITH (FORMAT csv, HEADER true);
SQL
```

> `\copy` (a psql client command) reads the file from wherever you ran psql —
> here, inside the container. Don't confuse it with SQL `COPY`, which reads from
> the *server's* filesystem and needs superuser/paths; `\copy` just works.

**Check it loaded:**

```bash
psql -U cs143 -d cs143 -c "\dt"                          # list tables
psql -U cs143 -d cs143 -c "SELECT count(*) FROM people;" # row count
```

Notes:

- **The imported data persists.** The downloaded file (e.g. `data.sql`) lives in
  the container's temporary layer and is discarded if you `rm` the container, but
  once it's imported the **tables** live in the `cs143-data` volume and survive
  stop/start/rm. You only re-import if you wipe the volume.
- **The dataset needs a URL** reachable from where you run Docker (course server,
  an S3/GCS bucket, GitHub raw, etc.). HTTPS works out of the box.
- **No URL? Copy a local file in** without any shared-folder config:
  ```bash
  docker cp ./data.sql cs143:/tmp/          # from your host shell
  ./shell.sh                                 # then, inside:
  #   psql -U cs143 -d cs143 -f /tmp/data.sql
  ```

---

## 6. Manage the container

> Tip: [`./shell.sh`](#easiest-path-the-shellsh-helper) wraps most of these
> (`up`, `stop`, `restart`, `status`, `logs`, `rm`, plus opening a shell/psql).
> The commands below are the manual equivalents.

Everyday commands (the container is named `cs143`):

| Task | Command |
|------|---------|
| See running containers | `docker ps` |
| See all containers (incl. stopped) | `docker ps -a` |
| Follow the logs | `docker logs -f cs143` |
| Stop it | `docker stop cs143` |
| Start it again | `docker start cs143` |
| Restart it | `docker restart cs143` |
| Open a shell inside it | `docker exec -it cs143 bash` |
| Open psql inside it | `docker exec -it cs143 psql -U cs143 -d cs143` |
| Remove it (must stop first) | `docker rm cs143` |
| Stop and remove in one step | `docker rm -f cs143` |

Because you used `--name cs143`, you can only have one container by that name at
a time. To recreate it (e.g. after changing options), remove the old one first:

```bash
docker rm -f cs143
docker run -d --name cs143 -p 5432:5432 -v cs143-data:/var/lib/postgresql/data cs143:latest
```

### Data and reset

- Your data lives in the **`cs143-data`** volume, not in the container. Removing
  the container with `docker rm` keeps the data; the next `docker run` with the
  same `-v cs143-data:…` reuses it.
- To wipe everything and start from a fresh empty `cs143` database:
  ```bash
  docker rm -f cs143
  docker volume rm cs143-data
  ```
  (The `cs143` user/db/password are only created on a fresh, empty data volume.)

### Update to a new image

```bash
docker pull cs143:latest      # or docker load -i the new file
docker rm -f cs143
docker run -d --name cs143 -p 5432:5432 -v cs143-data:/var/lib/postgresql/data cs143:latest
```

Your data in `cs143-data` is preserved across the update.

### Troubleshooting

- **`docker: command not found`** — Docker isn't installed or Docker Desktop
  isn't running. Start Docker Desktop (Mac/Windows) and try again.
- **`Cannot connect to the Docker daemon`** — the Docker engine isn't running
  (start Docker Desktop), or on Linux your user isn't in the `docker` group (see
  the install step).
- **`port is already allocated` / `address already in use`** — something else is
  using 5432 (maybe another Postgres). Use a different host port: `-p 5433:5432`.
- **`password authentication failed`** — the password is `cs143`. If you changed
  it once on an existing data volume, the old password persists; wipe the volume
  (see *Data and reset*) to reset.
- **`database "cs143" does not exist` / wrong user** — the bootstrap only runs on
  an empty data volume. Reset the volume as above.

---

## For instructors

### Building

The build is multi-architecture via `docker buildx`. `build.sh` creates a
`docker-container` builder and installs QEMU emulators the first time so both
architectures can be built on one machine.

Build both platforms into the build cache (multi-arch images can't be loaded
into the local docker store):

```bash
./build.sh
```

Build a single platform and load it locally so you can run/test it:

```bash
LOAD=1 PLATFORMS=linux/amd64 ./build.sh
```

Publish both architectures to a registry as one multi-arch manifest (this is
what students `docker pull`):

```bash
IMAGE=docker.io/youruser/cs143 TAG=1.0 PUSH=1 ./build.sh
```

Export a single-arch image to a file to hand out (students `docker load -i`):

```bash
LOAD=1 PLATFORMS=linux/amd64 ./build.sh
docker save cs143:latest -o cs143.tar
```

`build.sh` configuration (environment variables):

| Var | Default | Meaning |
|-----|---------|---------|
| `IMAGE` | `cs143` | Image name (use a registry-qualified name to push) |
| `TAG` | `latest` | Image tag |
| `PG_VERSION` | `16` | Postgres major version (base image tag) |
| `PLATFORMS` | `linux/amd64,linux/arm64` | Target platforms |
| `PUSH` | `0` | `1` → push to registry |
| `LOAD` | `0` | `1` → load a single-platform build into local docker |
| `SKIP_BINFMT` | `0` | `1` → skip installing QEMU emulators |

### Files

- `Dockerfile` — based on `postgres:<version>-bookworm`; adds `wget` (bash + psql
  already ship in the Debian image) and sets the bootstrap credentials.
- `build.sh` — the multi-architecture build script.

### Changing the baked-in credentials

Credentials are baked into the image as defaults for classroom convenience, which
is why `docker build` prints a `SecretsUsedInArgOrEnv` warning. They can be
overridden at run time without rebuilding:

```bash
docker run -d -e POSTGRES_USER=me -e POSTGRES_PASSWORD=secret -e POSTGRES_DB=mydb \
  -p 5432:5432 cs143:latest
```

Do not reuse this image where `cs143/cs143` would be a real secret.
