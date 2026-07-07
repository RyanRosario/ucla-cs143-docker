#!/usr/bin/env bash
#
# Entrypoint wrapper for local-dev convenience.
#
# For a throwaway local database we default to password-less "trust" auth so
# `docker run` just works. We set this at runtime (rather than via an ENV
# instruction in the Dockerfile) because buildx's SecretsUsedInArgOrEnv linter
# flags any ENV/ARG whose name contains AUTH/PASSWORD/TOKEN/KEY.
#
# We only apply the default when the operator hasn't chosen an auth strategy
# themselves, so `-e POSTGRES_PASSWORD=...` or an explicit
# `-e POSTGRES_HOST_AUTH_METHOD=...` still take precedence.
set -euo pipefail

if [ -z "${POSTGRES_HOST_AUTH_METHOD:-}" ] && [ -z "${POSTGRES_PASSWORD:-}" ]; then
    export POSTGRES_HOST_AUTH_METHOD=trust
fi

exec docker-entrypoint.sh "$@"
