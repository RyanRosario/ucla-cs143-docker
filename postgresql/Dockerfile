# Postgres image with bash, psql, wget and vim available.
#
# The official postgres image is Debian-based, so bash and the psql client
# already ship in it. We only need to add wget (plus ca-certificates so wget
# can talk to HTTPS endpoints) and vim as an in-container editor.
# PG 18 to match the CS143 course SQL dumps (produced by pg_dump 18, which emit
# PG18-only syntax like the \restrict meta-command and SET transaction_timeout;
# an older server rejects them and the load rolls back). Keep this in step with
# the version pg_dump used to create the dumps students download.
ARG PG_VERSION=18
FROM postgres:${PG_VERSION}-bookworm

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        wget \
        ca-certificates \
        vim \
    && rm -rf /var/lib/apt/lists/*

# Give the interactive shell a real OS user "cs143" with a home directory to
# land in (the container otherwise only has root and postgres). This is purely
# for the human dropping into a shell; the Postgres server still runs as the
# built-in "postgres" user. The login shell is bash so `./cs143.sh shell`
# behaves as expected.
RUN useradd --create-home --shell /bin/bash cs143

# Bootstrap credentials. On first start with an empty data directory the
# official entrypoint uses these to create a superuser "cs143" that owns a
# database named "cs143". As a superuser, cs143 can create/drop schemas and
# tables and import data without further grants.
#
# We intentionally do NOT bake a password into the image, and we do NOT set
# POSTGRES_HOST_AUTH_METHOD via ENV — buildx's SecretsUsedInArgOrEnv linter
# flags any ENV/ARG whose name contains AUTH. Instead, a thin entrypoint
# wrapper defaults to password-less "trust" auth for local dev only when the
# operator hasn't chosen otherwise. To use password auth, just pass
# `-e POSTGRES_PASSWORD=...` at `docker run` time.
ENV POSTGRES_USER=cs143 \
    POSTGRES_DB=cs143

# Client-side defaults so a bare `psql` (from any shell in the container)
# connects as the cs143 role to the cs143 database instead of falling back to
# libpq's default of "the current OS user" — inside the container that user is
# root, which yields `FATAL: role "root" does not exist`. These are libpq
# variables read by the psql *client*; the server ignores them, so they don't
# affect first-boot initialization (which uses POSTGRES_USER/POSTGRES_DB).
ENV PGUSER=cs143 \
    PGDATABASE=cs143

COPY set-default-auth.sh /usr/local/bin/set-default-auth.sh
RUN chmod +x /usr/local/bin/set-default-auth.sh

# Sanity check that the requested tools are present in the final image.
RUN command -v bash && command -v psql && command -v wget && command -v vim

ENTRYPOINT ["set-default-auth.sh"]
CMD ["postgres"]
