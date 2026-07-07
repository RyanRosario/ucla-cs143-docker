#!/usr/bin/env bash
#
# Build the Postgres-with-tools image for multiple architectures.
#
# Multi-arch images cannot be loaded into the local docker image store, so by
# default this builds both platforms and leaves the result in the build cache.
# To publish, set PUSH=1 and IMAGE to a registry-qualified name:
#
#     IMAGE=docker.io/youruser/cs143 PUSH=1 ./build.sh
#
# To get a runnable image locally instead, build a single platform with LOAD=1:
#
#     LOAD=1 PLATFORMS=linux/amd64 ./build.sh
#
set -euo pipefail

IMAGE="${IMAGE:-cs143}"
TAG="${TAG:-latest}"
PG_VERSION="${PG_VERSION:-18}"
PLATFORMS="${PLATFORMS:-linux/amd64,linux/arm64}"
BUILDER="${BUILDER:-cs143-builder}"

cd "$(dirname "$0")"

# A container-driver builder is required for multi-platform builds; the default
# "docker" driver can only build for the host architecture.
if ! docker buildx inspect "${BUILDER}" >/dev/null 2>&1; then
    echo ">> creating buildx builder '${BUILDER}'"
    docker buildx create --name "${BUILDER}" --driver docker-container --bootstrap
fi

# Register QEMU emulators so we can build non-native architectures. Harmless to
# re-run; skip by setting SKIP_BINFMT=1 if emulators are already installed.
if [ "${SKIP_BINFMT:-0}" != "1" ]; then
    echo ">> installing QEMU binfmt handlers"
    docker run --privileged --rm tonistiigi/binfmt --install all >/dev/null
fi

# Default to an explicit cache-only output. Leaving output unspecified makes
# buildx warn "No output specified..."; declaring type=cacheonly says the same
# thing on purpose (result stays in the build cache) without the warning.
output_args=(--output=type=cacheonly)
if [ "${PUSH:-0}" = "1" ]; then
    output_args=(--push)
elif [ "${LOAD:-0}" = "1" ]; then
    output_args=(--load)
fi

echo ">> building ${IMAGE}:${TAG} for ${PLATFORMS} (pg ${PG_VERSION})"
docker buildx build \
    --builder "${BUILDER}" \
    --platform "${PLATFORMS}" \
    --build-arg PG_VERSION="${PG_VERSION}" \
    --tag "${IMAGE}:${TAG}" \
    "${output_args[@]}" \
    .

echo ">> done"
