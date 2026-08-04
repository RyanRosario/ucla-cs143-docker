# Pinned to 24.04 (noble) on purpose: MongoDB still only publishes apt packages
# for noble, and the repo line below hardcodes that codename. `ubuntu:latest`
# now resolves to 26.04 (resolute), which none of these vendors target yet.
FROM ubuntu:24.04

LABEL image="CS 143 NoSQL"
LABEL maintainer="rrosario@cs.ucla.edu"
LABEL vendor="UCLA Computer Science"
LABEL edu.ucla.version="0.6.0"

ENV TZ="America/Los_Angeles"
ARG DEBIAN_FRONTEND="noninteractive"

# Bump these to move a database forward
ARG MONGODB_SERIES="8.2"
ARG NEO4J_SERIES="latest"
ARG ARANGODB_VERSION="3.12.4.3-1"

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# MongoDB, Redis and Neo4j in a single layer.
#
# Deliberately one RUN rather than three: every `apt update` writes ~50MB of
# package lists, and a layer keeps its own copy even after a later layer deletes
# them. Three separate installs froze three copies into the image.
#
# `--no-install-recommends` matters more than it looks: `python3-pip` recommends
# `build-essential`, which drags in a ~120MB C++ toolchain that nothing here
# compiles with, plus mesa-vulkan-drivers.
#
# The full (non-headless) JRE is NOT avoidable, so don't try. `neo4j` and
# `cypher-shell` depend on the virtual package `java21-runtime`, and only
# `openjdk-21-jre` provides it -- `openjdk-21-jre-headless` provides
# `java21-runtime-headless`, which does not satisfy them. That pulls
# libglx-mesa0 and LLVM (~180MB) into a server that never draws anything.
# Forcing headless-only needs an equivs dummy package, which then breaks
# `apt upgrade` for neo4j; not worth it here.
#
# NOTE: MongoDB has not published a server-8.2.asc; the 8.2 repo is signed with
# the same key served as server-8.0.asc (fpr 4B07 52C1 BCA2 38C0 B4EE 14DC 41DE
# 058A 4E7D CA05). Re-check this URL when bumping MONGODB_SERIES.
RUN set -eux; \
	apt-get update -qq; \
	apt-get install -y --no-install-recommends \
		ca-certificates curl wget gnupg nano unzip \
		python3 python3-pip debconf-utils; \
	codename="$(. /etc/os-release && echo "$VERSION_CODENAME")"; \
	\
	curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc \
		| gpg --dearmor -o /usr/share/keyrings/mongodb-server.gpg; \
	echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server.gpg ] https://repo.mongodb.org/apt/ubuntu noble/mongodb-org/${MONGODB_SERIES} multiverse" \
		> /etc/apt/sources.list.d/mongodb-org.list; \
	\
	curl -fsSL https://packages.redis.io/gpg \
		| gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg; \
	chmod 644 /usr/share/keyrings/redis-archive-keyring.gpg; \
	echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb ${codename} main" \
		> /etc/apt/sources.list.d/redis.list; \
	\
	curl -fsSL https://debian.neo4j.com/neotechnology.gpg.key \
		| gpg --dearmor -o /usr/share/keyrings/neo4j.gpg; \
	echo "deb [signed-by=/usr/share/keyrings/neo4j.gpg] https://debian.neo4j.com stable ${NEO4J_SERIES}" \
		> /etc/apt/sources.list.d/neo4j.list; \
	\
	apt-get update -qq; \
	apt-get install -y --no-install-recommends \
		mongodb-org redis neo4j; \
	mkdir -p /home/cs143/.config/mongodb/data /home/cs143/.config/mongodb/logs; \
	apt-get clean; \
	rm -rf /var/lib/apt/lists/*

# Install ArangoDB
# ArangoDB's apt repo is unmaintained (its signing key expired in 2025), so pull
# the community .deb directly and verify it by checksum instead. The postinst
# initializes the system database, which is why the debconf answers are preseeded.
# Kept in its own layer so bumping ARANGODB_VERSION doesn't rebuild everything above.
RUN set -eux; \
	arch="$(dpkg --print-architecture)"; \
	case "$arch" in \
		amd64) sha256="cc91ba31478e5feac8216cf7bcf4fcc63cdfcc1c82910056e60d43183e60edc6" ;; \
		arm64) sha256="7366ad4bea3967e9621b3ad16ade0272481ebbfd5def692ebdd2af1e8a0cd80c" ;; \
		*) echo "unsupported architecture: $arch" >&2; exit 1 ;; \
	esac; \
	curl -fsSL -o /tmp/arangodb3.deb \
		"https://download.arangodb.com/arangodb312/Community/Linux/arangodb3_${ARANGODB_VERSION}_${arch}.deb"; \
	echo "${sha256}  /tmp/arangodb3.deb" | sha256sum -c -; \
	echo "arangodb3 arangodb3/password password cs143" | debconf-set-selections; \
	echo "arangodb3 arangodb3/password_again password cs143" | debconf-set-selections; \
	echo "arangodb3 arangodb3/upgrade boolean true" | debconf-set-selections; \
	echo "arangodb3 arangodb3/storage_engine select rocksdb" | debconf-set-selections; \
	echo "arangodb3 arangodb3/backup boolean false" | debconf-set-selections; \
	apt-get install -y --no-install-recommends /tmp/arangodb3.deb; \
	rm -f /tmp/arangodb3.deb; \
	apt-get clean; \
	rm -rf /var/lib/apt/lists/*

# User environment, plus each database's data directory and config.
# One layer: these are all tiny metadata/config edits, and splitting them only
# adds layers.
RUN set -eux; \
	useradd -s /bin/bash -g users -d /home/cs143 cs143; \
	echo "cs143:cs143" | chpasswd; \
	echo "cs143 ALL=(ALL:ALL) ALL" >> /etc/sudoers; \
	mkdir -p /home/cs143/shared /home/cs143/data /home/cs143/.cache \
		/home/cs143/.config/neo4j \
		/home/cs143/.config/redis \
		/home/cs143/.config/chroma \
		/home/cs143/.config/arangodb3/log; \
	chown cs143:users /etc/redis; \
	\
	sed -i 's|/var/lib/|/home/cs143/.config/neo4j/|g' /etc/neo4j/neo4j.conf; \
	sed -i 's|#server.directories.run=.*|server.directories.run=/home/cs143/.config/neo4j/run|' /etc/neo4j/neo4j.conf; \
	sed -i 's|server.directories.logs=/var/log/neo4j|server.directories.logs=/home/cs143/.config/neo4j/log/neo4j|' /etc/neo4j/neo4j.conf; \
	sed -i 's|#dbms.security.auth_enabled=false|dbms.security.auth_enabled=false|' /etc/neo4j/neo4j.conf; \
	sed -i 's|#server.default_listen_address=0.0.0.0|server.default_listen_address=0.0.0.0|' /etc/neo4j/neo4j.conf; \
	chown -R cs143:users /etc/neo4j; \
	\
	mv /var/lib/arangodb3 /home/cs143/.config/arangodb3/data; \
	mv /var/lib/arangodb3-apps /home/cs143/.config/arangodb3/apps; \
	sed -i 's|^directory = /var/lib/arangodb3$|directory = /home/cs143/.config/arangodb3/data|' /etc/arangodb3/arangod.conf; \
	sed -i 's|^app-path = /var/lib/arangodb3-apps$|app-path = /home/cs143/.config/arangodb3/apps|' /etc/arangodb3/arangod.conf; \
	sed -i 's|^file = /var/log/arangodb3/arangod.log$|file = /home/cs143/.config/arangodb3/log/arangod.log|' /etc/arangodb3/arangod.conf; \
	sed -i 's|^endpoint = tcp://127.0.0.1:8529$|endpoint = tcp://0.0.0.0:8529|' /etc/arangodb3/arangod.conf; \
	sed -i 's|^authentication = true$|authentication = false|' /etc/arangodb3/arangod.conf; \
	sed -i 's|^uid = arangodb$|# uid = arangodb|' /etc/arangodb3/arangod.conf; \
	sed -i 's|^gid = arangodb$|# gid = arangodb|' /etc/arangodb3/arangod.conf; \
	chown -R cs143:users /etc/arangodb3; \
	\
	chown -R cs143:users /home/cs143

# Python drivers, and ChromaDB's default embedding model warmed into the image.
# Without the warm-up the first add()/query() a student runs blocks on an ~80MB
# download, which fails outright with no network. Chroma keeps the tarball
# alongside the model it extracted, so drop it once it's unpacked.
RUN set -eux; \
	pip install --break-system-packages --no-cache-dir \
		pymongo redis neo4j chromadb python-arango ipython; \
	ln -s /usr/bin/python3 /usr/bin/python; \
	echo "alias ipython='python -m IPython'" >> /home/cs143/.bashrc; \
	chown cs143:users /home/cs143/.bashrc; \
	HOME=/home/cs143 python3 -c \
		"from chromadb.utils.embedding_functions.onnx_mini_lm_l6_v2 import ONNXMiniLM_L6_V2; ONNXMiniLM_L6_V2()(['warmup'])"; \
	find /home/cs143/.cache -name '*.tar.gz' -delete; \
	chown -R cs143:users /home/cs143/.cache

VOLUME [ "/home/cs143/shared" ]
VOLUME [ "/home/cs143/data" ]

# Expose necessary ports
EXPOSE 27017 6379 7474 7687 8000 8529

COPY --chown=cs143:users --chmod=755 entrypoint.sh /home/cs143/.config/entrypoint.sh

# Set user and working directory
USER cs143
WORKDIR /home/cs143

ENTRYPOINT ["/home/cs143/.config/entrypoint.sh"]
CMD ["bash"]
