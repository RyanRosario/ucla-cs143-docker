# CS143 NoSQL image

One container with **five NoSQL databases** already installed, configured, and
started for you, plus the Python driver for each. It's built for both Intel/AMD
and Apple Silicon machines (`linux/amd64` and `linux/arm64`), so the same image
name works on every laptop.

When you open a shell you land in the home directory of a user named **`cs143`**
(password `cs143`, with `sudo`). All five databases are already running — you do
not start them yourself.

| Database | Version | Port(s) | Command-line client | Python driver |
|---|---|---|---|---|
| **MongoDB** | 8.2 | `27017` | `mongosh` | `pymongo` |
| **Redis** | 8.10 | `6379` | `redis-cli` | `redis` |
| **Neo4j** | 2026.06 | `7474` (browser), `7687` (Bolt) | `cypher-shell` | `neo4j` |
| **ArangoDB** | 3.12 | `8529` (API + web UI) | `arangosh` | `python-arango` |
| **ChromaDB** | 1.5 | `8000` (HTTP API) | `chroma` | `chromadb` |

**None of them require a username or password.** Authentication is turned off
across the board so you can focus on querying rather than credentials. That also
means you should not put anything private in this container, and should not
expose its ports to an untrusted network.

`ipython` is installed for interactive Python work.

> **Quick start (once Docker is installed):**
> ```bash
> docker run -d -it --name cs143-nosql \
>   -p 27017:27017 -p 6379:6379 -p 7474:7474 -p 7687:7687 -p 8000:8000 -p 8529:8529 \
>   ryanrosario/nosql:latest bash
> docker exec -it -u cs143 -w /home/cs143 cs143-nosql bash
> ```
> Give it a few minutes on the first start — see
> [Startup time and memory](#startup-time-and-memory).

---

## 1. Install Docker

Identical to the Postgres image — follow
[section 1 of the Postgres README](../postgresql/README.md#1-install-docker)
for macOS, Windows (WSL 2), and Linux instructions, then come back here.

Verify it works:

```bash
docker run --rm hello-world
```

---

## 2. Get the image

Pull the published image (Docker automatically downloads the right build for
your CPU):

```bash
docker pull ryanrosario/nosql:latest
```

Or build it yourself from this directory — see
[Building the image](#building-the-image).

---

## 3. Run the container

```bash
docker run -d -it --name cs143-nosql \
  -p 27017:27017 -p 6379:6379 -p 7474:7474 -p 7687:7687 -p 8000:8000 -p 8529:8529 \
  ryanrosario/nosql:latest bash
```

What each part means:

- `-d` — run in the background (detached).
- `-it` — keep a terminal attached to the container's main process. **This image
  needs it**: its main process is `bash`, and without a terminal `bash` hits
  end-of-input and exits the moment the databases finish starting — so the
  container dies on its own after about a minute.
- `--name cs143-nosql` — a friendly name so you can manage it later.
- `-p HOST:CONTAINER` — publish each database so you can reach it from your own
  machine. Drop any you don't need; if a port is already in use on your laptop,
  remap it (e.g. `-p 16379:6379`, then connect to port `16379`).

Then open a shell inside it:

```bash
docker exec -it -u cs143 -w /home/cs143 cs143-nosql bash
```

Typing `exit` leaves the shell but **leaves the databases running**.

### Startup time and memory

Five databases start in sequence, so the container is **not ready the instant
`docker run` returns** — Neo4j has a JVM to boot and ChromaDB starts last. On a
well-resourced laptop this is well under a minute; on a small or busy machine it
can take several minutes. If a client says "connection refused", wait and retry.

To watch them come up:

```bash
docker logs -f cs143-nosql      # Ctrl-C to stop following
```

You'll see a `...done!` line per database. Note those lines are printed after a
fixed pause, so on a slow machine a database may still be finishing up after its
line appears — the real test is whether a client connects.

**Give Docker at least 4 GB of RAM.** Steady state is roughly 800 MB (Neo4j's JVM
is the biggest single consumer at ~430 MB), but startup is heavier. On Docker
Desktop: **Settings → Resources → Memory**. Too little memory shows up as
databases that never become reachable, or a container that dies during startup.

---

## 4. Accessing each database

Everything below works **inside the container shell**
(`docker exec -it -u cs143 -w /home/cs143 cs143-nosql bash`). Where a database is
also reachable **from your own machine**, that's shown too — those require the
matching `-p` flag from section 3.

### MongoDB

Document store. No auth, so a bare `mongosh` connects.

```bash
mongosh                                    # opens the shell
```

```javascript
use cs143
db.movies.insertOne({ title: "Vertigo", year: 1958 })
db.movies.find({ year: { $lt: 1960 } })
```

Python:

```python
import pymongo
client = pymongo.MongoClient("mongodb://localhost:27017")
db = client.cs143
db.movies.insert_one({"title": "Vertigo", "year": 1958})
print(db.movies.find_one({"title": "Vertigo"}))
```

From your own machine (needs `mongosh` installed locally):

```bash
mongosh --host localhost --port 27017
```

Connection string for GUI tools (MongoDB Compass, …): `mongodb://localhost:27017`

### Redis

Key-value store. No password.

```bash
redis-cli
```

```
SET course cs143
GET course
LPUSH topics nosql graphs vectors
LRANGE topics 0 -1
HSET student:1 name Ana year 3
HGETALL student:1
```

Python:

```python
import redis
r = redis.Redis(host="localhost", port=6379, decode_responses=True)
r.set("course", "cs143")
print(r.get("course"))
```

From your own machine:

```bash
redis-cli -h localhost -p 6379
```

### Neo4j

Graph database, queried with Cypher. Authentication is **disabled**, so any
username/password is accepted (and `cypher-shell` needs no flags).

```bash
cypher-shell
```

```cypher
CREATE (a:Person {name: 'Ana'})-[:FRIEND]->(b:Person {name: 'Ben'});
MATCH (p:Person)-[:FRIEND]->(q:Person) RETURN p.name, q.name;
```

Python:

```python
from neo4j import GraphDatabase
driver = GraphDatabase.driver("bolt://localhost:7687")
records = driver.execute_query("MATCH (p:Person) RETURN p.name AS name").records
print([r["name"] for r in records])
```

**Neo4j Browser** — the visual query tool, and the easiest way to *see* a graph.
Open <http://localhost:7474> in your laptop's browser. If it prompts for
credentials, choose "No authentication", or just enter `neo4j`/`neo4j`.

Two ports, two protocols: **7474** is the browser UI over HTTP, **7687** is
Bolt, the protocol drivers use. You need `-p` on both to use the browser from
your machine.

### ArangoDB

Multi-model database (documents, graphs, key-value) queried with **AQL**.
Authentication is disabled.

```bash
arangosh --server.authentication false
```

```javascript
var db = require("@arangodb").db;
db._create("cities");
db.cities.insert({ name: "Los Angeles", pop: 3.8 });
db._query("FOR c IN cities FILTER c.pop > 1 RETURN c.name").toArray();
```

Python:

```python
from arango import ArangoClient
db = ArangoClient(hosts="http://localhost:8529").db("_system")
cities = db.create_collection("cities") if not db.has_collection("cities") else db.collection("cities")
cities.insert({"name": "Los Angeles", "pop": 3.8})
print(list(db.aql.execute("FOR c IN cities RETURN c.name")))
```

**Web UI** — open <http://localhost:8529> in your laptop's browser. It has a
query editor and a graph viewer. Use database `_system`; auth is off.

Quick check from anywhere:

```bash
curl http://localhost:8529/_api/version
```

### ChromaDB

Vector database, used for embeddings and similarity search. It runs as a server
on port 8000 and has **no web UI** — you use it from Python.

```python
import chromadb
client = chromadb.HttpClient(host="localhost", port=8000)

col = client.get_or_create_collection("lectures")
col.add(
    ids=["1", "2"],
    documents=["Graph databases store nodes and edges",
               "Vector databases store embeddings"],
)
print(col.query(query_texts=["what stores edges?"], n_results=1)["documents"])
```

Chroma embeds your text automatically with a model that is **already baked into
the image**, so this works with no internet connection and no download wait.

> Collection names must be **3–512 characters** (letters, digits, `.`, `_`, `-`,
> starting and ending alphanumeric). A short name like `"p"` is rejected.

You can also use Chroma **without the server**, storing straight to a directory:

```python
import chromadb
client = chromadb.PersistentClient(path="/home/cs143/data/mychroma")
```

Health check:

```bash
curl http://localhost:8000/api/v2/heartbeat
```

---

## 5. Connecting from another machine

Everything in section 4 also works from a **different computer** — a laptop
reaching the desktop where the container runs, a teammate on the same Wi-Fi, or
a TA helping you debug. All five databases already listen on every interface, so
there is nothing to reconfigure inside the container.

**1. Publish the ports** (the `-p` flags from section 3). Without them the
databases are reachable only from the machine running Docker — that's Docker's
default, and it's why nothing is exposed until you ask for it.

**2. Find the IP of the machine running the container:**

```bash
ipconfig getifaddr en0                 # macOS (Wi-Fi; use en1 for Ethernet)
hostname -I | awk '{print $1}'         # Linux / WSL
```

Say it's `192.168.1.50`. From the other machine:

```bash
mongosh --host 192.168.1.50 --port 27017
redis-cli -h 192.168.1.50 -p 6379
cypher-shell -a bolt://192.168.1.50:7687
curl http://192.168.1.50:8529/_api/version
curl http://192.168.1.50:8000/api/v2/heartbeat
```

and in Python, just swap the host:

```python
pymongo.MongoClient("mongodb://192.168.1.50:27017")
redis.Redis(host="192.168.1.50", port=6379)
neo4j.GraphDatabase.driver("bolt://192.168.1.50:7687")
ArangoClient(hosts="http://192.168.1.50:8529")
chromadb.HttpClient(host="192.168.1.50", port=8000)
```

The web UIs work the same way: ArangoDB at `http://192.168.1.50:8529`, Neo4j
Browser at `http://192.168.1.50:7474`.

### Neo4j Browser needs one extra flag

Neo4j tells the browser which Bolt address to connect to, and by default it says
`localhost` — so a browser on *another* machine would try to reach its own
computer and fail with "connection refused". Set **`ADVERTISED_HOST`** to the IP
or hostname other machines use, when you create the container:

```bash
docker run -d -it --name cs143-nosql -e ADVERTISED_HOST=192.168.1.50 \
  -p 27017:27017 -p 6379:6379 -p 7474:7474 -p 7687:7687 -p 8000:8000 -p 8529:8529 \
  ryanrosario/nosql:latest bash
```

You only need this for the Neo4j **Browser**. Drivers, `cypher-shell`, and the
other four databases work remotely without it. If you skip it, you can still use
the Browser by typing the Bolt URL (`bolt://192.168.1.50:7687`) into its connect
dialog yourself.

### Keep it to networks you trust

The databases have **no passwords**, so anyone who can reach those ports can read
and delete your data. On a home or phone-hotspot network that's fine. Two things
worth knowing:

- **On a shared or public network** (dorm Wi-Fi, a café, a campus network open to
  everyone), don't publish the ports. Either leave the `-p` flags off and work
  inside the container shell, or bind them to your own machine only:
  `-p 127.0.0.1:27017:27017`. That's also the reliable way to restrict a port —
  on Linux, Docker's published ports are **not** blocked by `ufw` rules, because
  Docker installs its own firewall rules ahead of ufw's.
- **To reach it across the internet, use an SSH tunnel** rather than opening
  ports to the world:
  ```bash
  ssh -L 27017:localhost:27017 -L 7687:localhost:7687 you@your-machine
  ```
  Then connect to `localhost` on the near side as if the databases were local.

---

## 6. Where your data lives

Each database keeps its files under `/home/cs143/.config/` inside the container:

| Database | Directory |
|---|---|
| MongoDB | `~/.config/mongodb/data` (logs in `…/logs`) |
| Redis | `~/.config/redis` (append-only file + `dump.rdb`) |
| Neo4j | `~/.config/neo4j` |
| ArangoDB | `~/.config/arangodb3/data` |
| ChromaDB | `~/.config/chroma/chroma.sqlite3` |

**What survives what:**

- `docker stop` / `docker start` / `docker restart` — **all data is kept**, in
  every one of the five databases.
- `docker rm` — **all data is destroyed.** These directories live in the
  container itself, not in a Docker volume.

Redis is configured with an append-only file so its data survives too; by
default Redis would lose recent writes when the container is killed.

To keep data even across `docker rm`, mount a named volume over the config
directory when you first create the container (Docker seeds a *named* volume
from the image, so the databases still start correctly):

```bash
docker run -d -it --name cs143-nosql -v cs143-nosql-data:/home/cs143/.config \
  -p 27017:27017 -p 6379:6379 -p 7474:7474 -p 7687:7687 -p 8000:8000 -p 8529:8529 \
  ryanrosario/nosql:latest bash
```

### Sharing files with your laptop

Two directories are set up as mount points: `/home/cs143/shared` and
`/home/cs143/data`. To make one of them a folder on your machine, bind-mount it:

```bash
docker run -d -it --name cs143-nosql -v "$PWD/shared:/home/cs143/shared" \
  -p 27017:27017 -p 6379:6379 -p 7474:7474 -p 7687:7687 -p 8000:8000 -p 8529:8529 \
  ryanrosario/nosql:latest bash
```

Anything you drop in `./shared` on your laptop appears in `/home/cs143/shared`
inside the container, and vice versa.

---

## 7. Manage the container

| Task | Command |
|------|---------|
| Open a shell | `docker exec -it -u cs143 -w /home/cs143 cs143-nosql bash` |
| See running containers | `docker ps` |
| Follow startup logs | `docker logs -f cs143-nosql` |
| Stop it (data kept) | `docker stop cs143-nosql` |
| Start it again | `docker start cs143-nosql` |
| Restart it | `docker restart cs143-nosql` |
| Remove it (**data lost**) | `docker rm -f cs143-nosql` |

### Troubleshooting

- **The container starts, then exits about a minute later.** You left off `-it`.
  The main process is `bash`, which needs a terminal; without one it exits as
  soon as the entrypoint finishes starting the databases, and the container
  stops with it.
- **"Connection refused" from a client.** The database probably hasn't finished
  starting — see [Startup time and memory](#startup-time-and-memory). Check with
  `docker logs cs143-nosql`.
- **`port is already allocated`.** Something on your laptop already uses that
  port (a local Redis or Mongo is common). Map a different host port, e.g.
  `-p 16379:6379`, and connect to `16379`.
- **A database never becomes reachable, or the container dies during startup.**
  Usually not enough memory — raise Docker Desktop's memory limit to 4 GB+.
- **Neo4j Browser asks for a password.** Auth is off; pick "No authentication",
  or enter anything (e.g. `neo4j`/`neo4j`).
- **Chroma rejects your collection name.** Names must be at least 3 characters.
- **Data disappeared.** You ran `docker rm`, which deletes it. Use a named volume
  (see [Where your data lives](#6-where-your-data-lives)) if you need it to
  outlive the container.

---

## For instructors

### Building the image

From this directory. A plain local build, for the architecture you're on:

```bash
docker build -t ryanrosario/nosql:latest .
```

Multi-architecture build (what students pull). The default `docker` driver
cannot do multi-platform builds, so create a `docker-container` builder once:

```bash
sudo apt install docker-buildx                       # if not already installed
docker buildx create --name cs143-builder --use --bootstrap
docker login
docker buildx build --builder cs143-builder --push \
  --platform linux/amd64,linux/arm64 \
  --tag ryanrosario/nosql:latest .
```

To build a single platform and load it locally so you can run and test it:

```bash
docker buildx build --load --platform linux/amd64 -t ryanrosario/nosql:test .
```

The image is roughly **2.9 GB**. The bulk is irreducible: ArangoDB ~450 MB,
`mongosh` ~300 MB, Neo4j ~270 MB, MongoDB server ~210 MB, plus `onnxruntime` and
the baked-in embedding model for ChromaDB.

Two things keep it from being smaller, both deliberate:

- **Neo4j forces the full JRE.** It depends on the virtual package
  `java21-runtime`, which only `openjdk-21-jre` provides — the headless JRE
  provides `java21-runtime-headless`, which doesn't satisfy it. That pulls in
  ~180 MB of mesa/LLVM for a server that never renders anything. Overriding it
  needs an equivs dummy package, which then breaks `apt upgrade` for neo4j.
- **`mongodb-org` includes `mongos`** (~160 MB), the sharding router. Installing
  `mongodb-org-server mongodb-mongosh mongodb-database-tools` instead would drop
  it, at the cost of not being able to demo a sharded cluster.

### Version pinning

The base image is pinned to **`ubuntu:24.04`** deliberately. MongoDB publishes
apt packages only up to `noble`, and the MongoDB repo line hardcodes that
codename; `ubuntu:latest` now resolves to 26.04, which no vendor here targets
yet. Keep the base and that repo line in step.

Database versions are `ARG`s at the top of the `Dockerfile`:

| Arg | Default | Notes |
|-----|---------|-------|
| `MONGODB_SERIES` | `8.2` | Repo path under `repo.mongodb.org` |
| `NEO4J_SERIES` | `latest` | Component in the Neo4j apt repo |
| `ARANGODB_VERSION` | `3.12.4.3-1` | Pinned `.deb`, checksummed per architecture |

Two things to know when bumping versions:

- **MongoDB's signing key.** There is no `server-8.2.asc`; the 8.2 repo is signed
  by the key published as `server-8.0.asc`. Re-check this when changing
  `MONGODB_SERIES`.
- **ArangoDB is installed from a checksummed `.deb`, not apt.** Their apt repo's
  signing key expired and the repo is unmaintained, so `apt install arangodb3`
  fails. Bumping `ARANGODB_VERSION` means updating both SHA256 values in the
  `Dockerfile`. Note their public download tops out well below their source
  releases.

### Configuration applied at build time

- Neo4j and ArangoDB have authentication **disabled**, and both listen on all
  interfaces so published ports work.
- Redis runs with `--protected-mode no` (it would otherwise refuse every
  non-loopback client) and with an append-only file for durability.
- Each database's data directory is relocated under `/home/cs143/.config/` and
  owned by `cs143`, so nothing runs as root.
- ChromaDB's default embedding model is downloaded during the build, so students
  don't hit an ~80 MB download on their first query.

### Runtime options

| Env var | Default | Effect |
|---------|---------|--------|
| `ADVERTISED_HOST` | unset | Rewrites `server.default_advertised_address` in `neo4j.conf` at startup so Neo4j Browser hands remote clients a reachable Bolt URL instead of `localhost`. Only affects Neo4j. |

### Files

- `Dockerfile` — the image.
- `entrypoint.sh` — starts all five databases, then `exec`s the container command.
  It's idempotent: each database is skipped if already running, and stale PID
  files from an unclean shutdown are cleaned up.
