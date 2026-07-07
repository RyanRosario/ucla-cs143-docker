#!/usr/bin/env bash
#
# Manage the cs143 Postgres container lifecycle from one script.
#
#   ./shell.sh            # ensure it's running, then drop into a bash shell
#   ./shell.sh shell      #   (same as above)
#   ./shell.sh psql       # ensure it's running, then drop into psql
#   ./shell.sh up         # create/start it in the background, don't attach
#   ./shell.sh stop       # stop it (container + data preserved)
#   ./shell.sh restart    # stop then start
#   ./shell.sh status     # show whether it exists / is running
#   ./shell.sh logs       # follow Postgres logs (Ctrl-C to detach)
#   ./shell.sh rm         # stop and delete the container (data destroyed)
#   ./shell.sh help       # this message
#
# Config (override via env): NAME, IMAGE, PORT
#
#     PORT=5433 ./shell.sh up
#
set -euo pipefail

NAME="${NAME:-cs143}"
IMAGE="${IMAGE:-cs143:latest}"
PORT="${PORT:-5432}"
VOLUME="${VOLUME:-cs143-data}"   # named volume so data survives 'rm'; set empty to disable

# --- small helpers ---------------------------------------------------------

# Scope to containers explicitly: bare `docker inspect NAME` also matches an
# *image* named NAME, which would make exists() lie when the image is 'cs143'.
exists()  { docker container inspect "${NAME}" >/dev/null 2>&1; }
running() { [ "$(docker container inspect -f '{{.State.Running}}' "${NAME}" 2>/dev/null)" = "true" ]; }

# Bring the container to a running state, creating it the first time and
# starting it if it exists but is stopped. No-op if it's already running.
ensure_running() {
    if ! exists; then
        echo ">> creating container '${NAME}' from ${IMAGE} (port ${PORT})"
        local vol_args=()
        [ -n "${VOLUME}" ] && vol_args=(-v "${VOLUME}:/var/lib/postgresql/data")
        docker run -d --name "${NAME}" -p "${PORT}:5432" "${vol_args[@]}" "${IMAGE}" >/dev/null
    elif ! running; then
        echo ">> starting existing container '${NAME}'"
        docker start "${NAME}" >/dev/null
    fi
}

# Block until Postgres is accepting connections (or give up after ~30s) so
# psql works immediately after this returns.
wait_ready() {
    for _ in $(seq 1 30); do
        docker exec "${NAME}" pg_isready -U cs143 -d cs143 >/dev/null 2>&1 && return 0
        sleep 1
    done
    echo ">> warning: Postgres did not report ready within 30s" >&2
}

# --- subcommands -----------------------------------------------------------

cmd_shell() {
    ensure_running; wait_ready
    echo ">> entering bash (Postgres stays up on 'exit'; './cs143.sh stop' to stop container)"
    # Give the interactive shell a 'cs143' prompt. --norc keeps the exported PS1
    # from being clobbered by the image's default bashrc. PGUSER/PGDATABASE make
    # a bare `psql` connect as cs143 to the cs143 db (libpq otherwise defaults to
    # the OS user 'root', giving `FATAL: role "root" does not exist`). The image
    # sets these too; exporting here also fixes containers built before that.
    #
    # Note: no `exec` here so control returns to the script when the user exits
    # the shell, letting us print the stop-to-save-resources hint below. `|| true`
    # keeps `set -e` from aborting on a non-zero exit status from the shell.
    docker exec -it "${NAME}" bash -c 'export PS1="cs143\$ " PGUSER=cs143 PGDATABASE=cs143; exec bash --norc -i' || true
    echo ">> To save resources, you may want to stop the container using ./cs143.sh stop. You can always start it again with ./cs143.sh start."
}

cmd_psql() {
    ensure_running; wait_ready
    echo ">> entering psql (Postgres stays up on '\\q')"
    # No `exec` (and `|| true`) so we regain control after the user quits psql
    # and can print the stop-to-save-resources hint.
    docker exec -it "${NAME}" psql -U cs143 -d cs143 || true
    echo ">> To save resources, you may want to stop the container using ./cs143.sh stop. You can always start it again with ./cs143.sh start."
}

cmd_up() {
    ensure_running; wait_ready
    echo ">> '${NAME}' is up on localhost:${PORT}"
}

cmd_stop() {
    if running; then docker stop "${NAME}" >/dev/null && echo ">> stopped '${NAME}'"
    else echo ">> '${NAME}' is not running"; fi
}

cmd_restart() { cmd_stop; ensure_running; wait_ready; echo ">> restarted '${NAME}'"; }

cmd_status() {
    if ! exists; then echo ">> '${NAME}' does not exist (run './shell.sh up' to create it)"; return; fi
    docker ps -a --filter "name=^/${NAME}$" \
        --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
}

cmd_logs() { exists || { echo ">> '${NAME}' does not exist"; exit 1; }; exec docker logs -f "${NAME}"; }

cmd_rm() {
    if exists; then
        docker rm -f "${NAME}" >/dev/null && echo ">> removed container '${NAME}'"
        [ -n "${VOLUME}" ] && echo ">> data volume '${VOLUME}' kept; 'docker volume rm ${VOLUME}' to wipe it"
    else echo ">> '${NAME}' does not exist"; fi
}

cmd_help() { sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; }

# --- dispatch --------------------------------------------------------------

case "${1:-shell}" in
    shell|"")   cmd_shell   ;;
    psql)       cmd_psql    ;;
    up|start)   cmd_up      ;;
    stop)       cmd_stop    ;;
    restart)    cmd_restart ;;
    status|ps)  cmd_status  ;;
    logs)       cmd_logs    ;;
    rm|destroy) cmd_rm      ;;
    help|-h|--help) cmd_help ;;
    *) echo ">> unknown command: $1" >&2; cmd_help; exit 1 ;;
esac
