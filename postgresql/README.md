# CS143 Postgres image

A ready-to-use PostgreSQL container for CS143. It's the official Postgres image
(**PostgreSQL 18**) plus `bash`, `psql`, `wget`, and `vim`, and it's built for
both Intel/AMD and Apple Silicon / ARM machines (`linux/amd64` and
`linux/arm64`), so the same image name works on every laptop.

When you open a shell in it, you land in the home directory of a user named
**`cs143`** (i.e. at `~`), with `vim` available for editing files.

On first start it creates:

- a superuser **`cs143`** with password **`cs143`**
- a database **`cs143`** owned by `cs143`

`cs143` is a superuser, so it can create and drop schemas and tables, import
data, etc. without any extra setup.

| | |
|---|---|
| **Image (Docker Hub)** | `ryanrosario/cs143-ucla:latest` |
| **Host / port** | `localhost` : `5432` |
| **Database** | `cs143` |
| **Username** | `cs143` |
| **Password** | `cs143` |

> **Quick start (once Docker is installed):**
> ```bash
> curl -fsSL -o cs143.sh https://raw.githubusercontent.com/RyanRosario/ucla-cs143-docker/main/postgresql/cs143.sh
> chmod +x cs143.sh
> ./cs143.sh            # pulls/creates/starts the container, drops you into a shell
> ```
> The rest of this README explains every step in detail.

---

## 1. Install Docker

You only need **Docker** — Docker Desktop on Mac/Windows, or Docker Engine on
Linux. Pick your operating system below, then confirm it works with the
`hello-world` test at the end of each section.

> For directions on using Docker Desktop, see
> [here](https://docs.docker.com/desktop/).

### macOS

1. Find your chip: click the  Apple menu → **About This Mac**. It says either
   **Apple M1/M2/M3/M4…** (Apple Silicon) or **Intel**.
2. Download **Docker Desktop** for your chip from
   <https://www.docker.com/products/docker-desktop/> (choose "Apple Silicon" or
   "Intel Chip" to match step 1).
3. Open the downloaded `Docker.dmg` and drag **Docker** into **Applications**.
4. Launch **Docker** from Applications and accept the prompts. When the whale
   icon 🐳 in the menu bar stops animating, Docker is ready.
5. Verify in **Terminal** (Applications → Utilities → Terminal):
   ```bash
   docker run --rm hello-world
   ```
   You should see "Hello from Docker!".

> Homebrew alternative: `brew install --cask docker`, then launch Docker Desktop
> once so it can finish setup.

### Windows (with WSL 2)

Docker Desktop on Windows runs the Linux container inside **WSL 2** (Windows
Subsystem for Linux). You'll install WSL 2, install Docker Desktop, then run the
CS143 commands from inside a WSL/Ubuntu shell.

1. **Requirements:** Windows 10 (64-bit, version 2004+) or Windows 11.
2. **Install WSL 2 + Ubuntu.** Open **PowerShell as Administrator**
   (Start → type "PowerShell" → right-click → *Run as administrator*) and run:
   ```powershell
   wsl --install
   ```
   This enables WSL 2 and installs Ubuntu by default. **Reboot** when prompted.
   After reboot, Ubuntu opens and asks you to create a Linux username and
   password — remember these (the password is for `sudo` inside Ubuntu).
   - Already have WSL? Make sure it's version 2: `wsl --set-default-version 2`.
3. **Install Docker Desktop.** Download and run the **Docker Desktop Installer**
   from <https://www.docker.com/products/docker-desktop/>. During install, keep
   **"Use WSL 2 instead of Hyper-V"** checked.
4. **Turn on WSL integration.** Start **Docker Desktop**, open
   **Settings → Resources → WSL Integration**, and enable integration for your
   **Ubuntu** distro. This is what makes the `docker` command available *inside*
   Ubuntu. Wait until Docker Desktop says **"Engine running"**.
5. **Open your Ubuntu terminal** (Start → "Ubuntu") and verify:
   ```bash
   docker run --rm hello-world
   ```

> **Run all CS143 commands from the Ubuntu/WSL terminal**, not PowerShell. The
> `cs143.sh` helper is a bash script and expects a Linux shell. Your files in
> WSL live under your Linux home (`~`), which you can reach from Windows at
> `\\wsl$\Ubuntu\home\<you>` if you ever need Explorer.

### Linux

Install **Docker Engine** with Docker's convenience script (works on Ubuntu,
Debian, Fedora, and more):

```bash
curl -fsSL https://get.docker.com | sudo sh
```

Then let your user run Docker without `sudo`. Log out and back in afterward (or
run `newgrp docker`) so the new group membership takes effect:

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

## 2. Get the `cs143.sh` helper script

This repo includes **`cs143.sh`**, a single script that manages the whole
container lifecycle so you don't have to remember individual `docker` commands.
It pulls the image if needed, creates the container the first time, starts it if
it's stopped, waits until Postgres is actually ready, and drops you into a
shell.

Pick **one** of the two ways to get it.

### Option A — download just the script (simplest)

In a folder you want to work from, download `cs143.sh` and make it executable:

```bash
# with curl:
curl -fsSL -o cs143.sh https://raw.githubusercontent.com/RyanRosario/ucla-cs143-docker/main/postgresql/cs143.sh

# ...or with wget:
wget -O cs143.sh https://raw.githubusercontent.com/RyanRosario/ucla-cs143-docker/main/postgresql/cs143.sh

chmod +x cs143.sh          # make it runnable (needed on Mac/Linux/WSL)
```

### Option B — clone the whole repo

This also gets you the per-assignment data loaders (e.g. `load-hw2.sh`):

```bash
git clone https://github.com/RyanRosario/ucla-cs143-docker.git
cd ucla-cs143-docker/postgresql
chmod +x cs143.sh
```

> **`chmod +x`** marks the script as executable so you can run it with
> `./cs143.sh`. If you skip it, you'll get `Permission denied`; you can also
> always run it as `bash cs143.sh` without changing permissions.
>
> **Windows:** do this in the **Ubuntu/WSL** terminal. If the script ever fails
> with `bad interpreter: /usr/bin/env bash^M`, it picked up Windows (CRLF) line
> endings — re-download it inside WSL, or run `sed -i 's/\r$//' cs143.sh`.

---

## 3. Pull the image from Docker Hub

`cs143.sh` will pull the image automatically the first time you run it, but you
can also pull it explicitly. Docker downloads the correct build for your CPU
(Intel/AMD or Apple Silicon) automatically:

```bash
docker pull ryanrosario/cs143-ucla:latest
```

The `cs143.sh` script defaults to this image, so there's nothing to configure.

---

## 4. Use the `cs143.sh` script

From the folder containing `cs143.sh`:

```bash
./cs143.sh          # ensure the container is running, then open a bash shell in it
```

The first run pulls the image and initializes the database (a few seconds).
Inside that shell you start at `~` as user `cs143`, Postgres is already running
in the background, and you can connect with a bare `psql` (no flags needed —
it's preconfigured to connect as `cs143` to the `cs143` database):

```bash
cs143$ psql
```

Typing `exit` leaves the shell but **leaves Postgres running**. All commands:

| Command | What it does |
|---------|--------------|
| `./cs143.sh` or `./cs143.sh shell` | Ensure it's running, then open a **bash** shell inside it (lands at `~` as `cs143`) |
| `./cs143.sh psql` | Ensure it's running, then open **psql** directly |
| `./cs143.sh up` (or `start`) | Create/start it in the background, don't attach |
| `./cs143.sh stop` | Stop it (container + data preserved) |
| `./cs143.sh restart` | Stop then start |
| `./cs143.sh status` (or `ps`) | Show whether it exists / is running |
| `./cs143.sh logs` | Follow the Postgres logs (`Ctrl-C` to detach) |
| `./cs143.sh rm` | Remove the container (the `cs143-data` volume is **kept**) |
| `./cs143.sh help` | Show usage |

> On **Windows**, run these from the **Ubuntu/WSL** terminal (or Git Bash with
> `bash cs143.sh …`). PowerShell can't run `./cs143.sh` directly — if you prefer
> PowerShell, use the manual `docker` commands in the sections below.

**Nothing to set up first** — you don't create any directories, paths, or
permissions. The script stores data in a Docker-managed named volume
(`cs143-data`) that Docker creates automatically, and Postgres manages ownership
inside the container. You only need Docker installed (section 1), the script
(section 2), and network access to pull the image (section 3).

You can override defaults with environment variables:

| Var | Default | Meaning |
|-----|---------|---------|
| `NAME` | `cs143` | Container name |
| `IMAGE` | `cs143:latest` | Image to run (set to `ryanrosario/cs143-ucla:latest` to use the published image) |
| `PORT` | `5432` | Host port mapped to Postgres |
| `VOLUME` | `cs143-data` | Named data volume (set empty to store data only in the container) |

```bash
PORT=5433 ./cs143.sh up      # e.g. if 5432 is already in use
IMAGE=ryanrosario/cs143-ucla:latest ./cs143.sh   # use the Docker Hub image explicitly
```

> If you downloaded only the script (Option A) and haven't built a local
> `cs143:latest`, run with `IMAGE=ryanrosario/cs143-ucla:latest` (or `export
> IMAGE=ryanrosario/cs143-ucla:latest` once in your shell) so it uses the
> published image.

### Windows & Docker Desktop notes

Everything **inside** the container is identical on every platform — it's the
same Linux Postgres image on Mac, Windows, and Linux, so `psql`, `wget`, `vim`,
data loading, ports, and credentials all behave the same. Only a few
**host-side** things differ:

- **`./cs143.sh` needs a bash shell.** On Windows use the **Ubuntu/WSL 2**
  terminal (recommended — Docker Desktop's WSL integration provides `docker`
  there), or **Git Bash** with `bash cs143.sh`. PowerShell users can use the
  manual `docker` commands below instead.
- **Keep the script's line endings as LF** (see the CRLF note in section 2).
- **The data volume isn't a browsable folder on Docker Desktop.** On Docker
  Desktop the `cs143-data` volume lives inside Docker's Linux VM, not at a path
  you can open in Finder/Explorer. You manage it via `docker volume` and `psql`
  either way.

Connecting to `localhost:5432` from your host works the same on all platforms —
Docker Desktop publishes the port to your machine's localhost automatically.

The rest of this README explains the equivalent **manual** `docker` commands, in
case you prefer to run them yourself or need to understand what the script does.

---

## 5. Manual alternative: start the container yourself

If you'd rather not use `cs143.sh`, run the container directly:

```bash
docker run -d --name cs143 -p 5432:5432 \
  -v cs143-data:/var/lib/postgresql \
  ryanrosario/cs143-ucla:latest
```

What each part means:

- `-d` — run in the background (detached).
- `--name cs143` — give the container a friendly name so you can manage it.
- `-p 5432:5432` — publish Postgres so you can reach it from your machine
  (`host-port:container-port`). This is what makes it accessible **outside** the
  container.
- `-v cs143-data:/var/lib/postgresql` — store the data in a named volume so it
  **survives** stopping/removing the container. Drop this if you don't care
  about keeping data.

> **Volume path note (PostgreSQL 18):** the mount point is
> `/var/lib/postgresql`, **not** `/var/lib/postgresql/data`. PG 18's image keeps
> data in a major-version subdirectory and rejects a mount at the old `.../data`
> path. If you're upgrading from an older PG 16 setup, see
> [Data and reset](#data-and-reset) — a PG 16 volume can't be started by PG 18.

The first start takes a few seconds while it initializes the `cs143` database.

---

## 6. Connect to Postgres

**From a shell inside the container** — with the helper:

```bash
./cs143.sh psql
```

or manually:

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

The server listens on all interfaces and requires the `cs143` password for
network connections, so nothing extra is needed on the server side — the other
machine connects to **your host's IP** on port 5432:

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

## 7. Load data into the database

You don't need any shared folders or host setup to get data in — the image ships
with `wget`, so you download the data **inside the container** straight into
Postgres. Open a shell first:

```bash
./cs143.sh            # opens a bash shell inside the running container
```

### Homework data loaders

For assignments that ship a loader script (e.g. **`load-hw2.sh`** in this repo),
just run it inside the container shell — it downloads the dataset and imports it
for you, and is safe to re-run (it skips if the data is already loaded):

```bash
# inside the container's shell (./cs143.sh)
bash load-hw2.sh
```

If you cloned the repo (Option B), the loader is already alongside `cs143.sh`.
To get it into the container, either clone inside the shell or copy it in from
your host:

```bash
docker cp ./load-hw2.sh cs143:/home/cs143/     # from your host shell, then run it inside
```

### Loading a SQL dump yourself

```bash
# inside the container's shell
wget https://example.com/path/to/data.sql        # download it
psql -f data.sql                                  # run it into the database
```

### Loading a CSV into a table you define

```bash
# inside the container's shell
wget https://example.com/path/to/people.csv

psql <<'SQL'
CREATE TABLE people (id int, name text, age int);
\copy people FROM 'people.csv' WITH (FORMAT csv, HEADER true);
SQL
```

> `\copy` (a psql client command) reads the file from wherever you ran psql —
> here, inside the container. Don't confuse it with SQL `COPY`, which reads from
> the *server's* filesystem; `\copy` just works.

**Check it loaded:**

```bash
psql -c "\dt"                          # list tables
psql -c "SELECT count(*) FROM people;" # row count
```

Notes:

- **The imported data persists.** The downloaded file lives in the container's
  temporary layer and is discarded if you `rm` the container, but once it's
  imported the **tables** live in the `cs143-data` volume and survive
  stop/start/rm. You only re-import if you wipe the volume.
- **The dataset needs a URL** reachable from where you run Docker (course server,
  an S3/GCS bucket, GitHub raw, etc.). HTTPS works out of the box.

---

## 8. Manage the container

> Tip: [`./cs143.sh`](#4-use-the-cs143sh-script) wraps most of these (`up`,
> `stop`, `restart`, `status`, `logs`, `rm`, plus opening a shell/psql). The
> commands below are the manual equivalents.

Everyday commands (the container is named `cs143`):

| Task | Command |
|------|---------|
| See running containers | `docker ps` |
| See all containers (incl. stopped) | `docker ps -a` |
| Follow the logs | `docker logs -f cs143` |
| Stop it | `docker stop cs143` |
| Start it again | `docker start cs143` |
| Restart it | `docker restart cs143` |
| Open a shell inside it | `docker exec -it -u cs143 -w /home/cs143 cs143 bash` |
| Open psql inside it | `docker exec -it cs143 psql -U cs143 -d cs143` |
| Remove it (must stop first) | `docker rm cs143` |
| Stop and remove in one step | `docker rm -f cs143` |

Because you used `--name cs143`, you can only have one container by that name at
a time. To recreate it (e.g. after changing options), remove the old one first:

```bash
docker rm -f cs143
docker run -d --name cs143 -p 5432:5432 -v cs143-data:/var/lib/postgresql ryanrosario/cs143-ucla:latest
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
- **Upgrading from an older PG 16 image?** A PG 16 data volume **cannot** be
  started by this PG 18 image — the container will exit with an error about data
  in `/var/lib/postgresql/data`. Since the volume only held course data you can
  re-load, wipe it and start fresh:
  ```bash
  ./cs143.sh rm                 # or: docker rm -f cs143
  docker volume rm cs143-data
  ./cs143.sh up                 # recreates on PG 18, then re-run your data loader
  ```

### Update to a new image

```bash
docker pull ryanrosario/cs143-ucla:latest
docker rm -f cs143
docker run -d --name cs143 -p 5432:5432 -v cs143-data:/var/lib/postgresql ryanrosario/cs143-ucla:latest
```

Your data in `cs143-data` is preserved across the update (as long as the Postgres
major version doesn't change).

### Troubleshooting

- **`docker: command not found`** — Docker isn't installed or Docker Desktop
  isn't running. Start Docker Desktop (Mac/Windows) and try again. On Windows,
  make sure you're in the **Ubuntu/WSL** terminal with WSL integration enabled.
- **`Cannot connect to the Docker daemon`** — the Docker engine isn't running
  (start Docker Desktop), or on Linux your user isn't in the `docker` group (see
  the install step).
- **`Permission denied` running `./cs143.sh`** — run `chmod +x cs143.sh`, or run
  it as `bash cs143.sh`.
- **`bad interpreter: /usr/bin/env bash^M`** — the script has Windows (CRLF)
  line endings. Re-download it inside WSL, or run `sed -i 's/\r$//' cs143.sh`.
- **`unable to find user cs143: no matching entries in passwd file`** — your
  container was built from an older image without the `cs143` user. Recreate it:
  `./cs143.sh rm && ./cs143.sh up` (wipe the volume too if it's a PG 16 volume,
  as in *Data and reset*).
- **`port is already allocated` / `address already in use`** — something else is
  using 5432 (maybe another Postgres). Use a different host port:
  `PORT=5433 ./cs143.sh up`, or `-p 5433:5432` manually.
- **`password authentication failed`** — the password is `cs143`. If you changed
  it once on an existing data volume, the old password persists; wipe the volume
  (see *Data and reset*) to reset.
- **`database "cs143" does not exist` / wrong user** — the bootstrap only runs on
  an empty data volume. Reset the volume as above.
- **Container exits immediately, logs mention data in
  `/var/lib/postgresql/data`** — a PG 16 volume under PG 18. See the upgrade note
  in *Data and reset*.

---

## For instructors

### Building

The build is multi-architecture via `docker buildx`. `build.sh` creates a
`docker-container` builder and installs QEMU emulators the first time so both
architectures can be built on one machine. (The default `docker` driver **cannot**
do multi-platform builds — if you build by hand, pass `--builder cs143-builder`
or your build fails with "Multi-platform build is not supported for the docker
driver.")

Build both platforms into the build cache (multi-arch images can't be loaded
into the local docker store):

```bash
./build.sh
```

Build a single platform and load it locally so you can run/test it:

```bash
LOAD=1 PLATFORMS=linux/amd64 ./build.sh
```

Publish both architectures to Docker Hub as one multi-arch manifest (this is what
students `docker pull`). Run `docker login` first:

```bash
IMAGE=ryanrosario/cs143-ucla TAG=latest PUSH=1 ./build.sh
```

Or by hand (note the explicit `--builder` so it doesn't fall back to the `docker`
driver):

```bash
docker buildx build --builder cs143-builder --push \
  --platform linux/amd64,linux/arm64 \
  --tag ryanrosario/cs143-ucla:latest .
```

Export a single-arch image to a file to hand out (students `docker load -i`):

```bash
LOAD=1 PLATFORMS=linux/amd64 ./build.sh
docker save cs143:latest -o cs143.tar
```

`build.sh` configuration (environment variables):

| Var | Default | Meaning |
|-----|---------|---------|
| `IMAGE` | `cs143` | Image name (use a registry-qualified name to push, e.g. `ryanrosario/cs143-ucla`) |
| `TAG` | `latest` | Image tag |
| `PG_VERSION` | `18` | Postgres major version (base image tag) |
| `PLATFORMS` | `linux/amd64,linux/arm64` | Target platforms |
| `PUSH` | `0` | `1` → push to registry |
| `LOAD` | `0` | `1` → load a single-platform build into local docker |
| `SKIP_BINFMT` | `0` | `1` → skip installing QEMU emulators |

> **Keep `PG_VERSION` in step with the course SQL dumps.** The dumps are produced
> by `pg_dump 18` and use PG18-only syntax (`\restrict`, `SET
> transaction_timeout`). An older server rejects them and the load rolls back, so
> the image and the dumps must share a major version.

### Files

- `Dockerfile` — based on `postgres:<version>-bookworm`; adds `wget` and `vim`
  (bash + psql already ship in the Debian image), creates the `cs143` OS user
  with a home directory, and sets the bootstrap credentials.
- `cs143.sh` — container lifecycle helper (shell/psql/up/stop/restart/status/
  logs/rm).
- `load-hw2.sh` — example homework data loader (downloads + imports the HW2
  dump, idempotent).
- `build.sh` — the multi-architecture build script.

### Changing the baked-in credentials

Credentials are baked into the image as defaults for classroom convenience, which
is why `docker build` prints a `SecretsUsedInArgOrEnv` warning. They can be
overridden at run time without rebuilding:

```bash
docker run -d -e POSTGRES_USER=me -e POSTGRES_PASSWORD=secret -e POSTGRES_DB=mydb \
  -p 5432:5432 ryanrosario/cs143-ucla:latest
```

Do not reuse this image where `cs143/cs143` would be a real secret.

---

## End of Term

When the course is over and you no longer need the database, clean up so it
stops using disk and (on Docker Desktop) memory. Do this in order.

**1. Stop the container** (this alone frees CPU/RAM; your data is untouched):

```bash
./cs143.sh stop           # or: docker stop cs143
```

**2. Delete the container** (removes the container but **keeps** the `cs143-data`
volume, so you could recreate it later with your data intact):

```bash
./cs143.sh rm             # or: docker rm -f cs143
```

**3. Delete the data volume** (this permanently erases the `cs143` database —
all your tables and rows). **Only do this once you're sure you're done:**

```bash
docker volume rm cs143-data
```

**4. (Optional) Delete the image** to reclaim the ~500 MB it occupies:

```bash
docker rmi ryanrosario/cs143-ucla:latest
```

To confirm everything is gone:

```bash
docker ps -a | grep cs143          # should print nothing
docker volume ls | grep cs143-data # should print nothing
docker images | grep cs143         # should print nothing after step 4
```

> **One command to remove the container and its data together** (skips keeping
> the volume):
> ```bash
> docker rm -f cs143 && docker volume rm cs143-data
> ```
> On Docker Desktop you can also do all of this from the GUI: the
> **Containers**, **Volumes**, and **Images** tabs each have a delete (🗑️)
> button — see the [Docker Desktop docs](https://docs.docker.com/desktop/).
