# Postgres image with bash, psql and wget available.
#
# The official postgres image is Debian-based, so bash and the psql client
# already ship in it. We only need to add wget (plus ca-certificates so wget
# can talk to HTTPS endpoints).
ARG PG_VERSION=16
FROM postgres:${PG_VERSION}-bookworm

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        wget \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

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

# Sanity check that the three requested tools are present in the final image.
RUN command -v bash && command -v psql && command -v wget

ENTRYPOINT ["set-default-auth.sh"]
CMD ["postgres"]
