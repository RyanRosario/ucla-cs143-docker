#!/bin/bash

CONFIG_DIR="/home/cs143/.config"

# Overwrite the "Starting X..." line with "Starting X...done!". `docker run`
# without -t has no $TERM, so fall back to just printing the line there.
done_msg() {
    if [ -t 1 ]; then
        tput cuu1 2>/dev/null
        tput el 2>/dev/null
    fi
    echo "$1...done!"
}

# --- Check & Start MongoDB ---
if pgrep -x "mongod" > /dev/null; then
    echo "MongoDB is already running!"
else
    echo "Starting MongoDB..."
    mongod --dbpath "$CONFIG_DIR/mongodb/data" --bind_ip_all --fork --logpath "$CONFIG_DIR/mongodb/logs/mongod.log" > /dev/null 2>&1
    sleep 5
    done_msg "Starting MongoDB"
fi

# --- Check & Start Redis ---
if pgrep -x "redis-server" > /dev/null; then
    echo "Redis is already running!"
else
    echo "Starting Redis..."
    # protected-mode would refuse every non-loopback client, so `docker run -p
    # 6379:6379` would connect and then be denied. Off here for the same reason
    # Neo4j and ArangoDB run without auth in this image.
    #
    # Persistence: redis is a child of PID 1 here, so a container stop SIGKILLs
    # it with no chance to snapshot. RDB save points alone would still drop
    # anything written in the last 60s, so keep an AOF (fsync every second) --
    # that is what actually survives the kill. Both land in .config/redis
    # rather than the cwd, so they persist wherever the student runs from.
    redis-server --daemonize yes --protected-mode no \
                 --dir "$CONFIG_DIR/redis" --appendonly yes --save 60 1
    sleep 2
    done_msg "Starting Redis"
fi

# --- Remote access for Neo4j Browser ---
# Neo4j hands the browser a Bolt URL built from its advertised address, which
# defaults to localhost. A student opening the browser from another machine
# would be told to connect to their OWN localhost, and it fails. Set
# ADVERTISED_HOST to the hostname/IP that clients use to reach this container.
if [ -n "$ADVERTISED_HOST" ]; then
    sed -i -E "s|^#?server\.default_advertised_address=.*|server.default_advertised_address=${ADVERTISED_HOST}|" \
        /etc/neo4j/neo4j.conf
    echo "Neo4j will advertise itself as ${ADVERTISED_HOST}"
fi

# --- Fix & Start Neo4j ---
NEO4J_PID_FILE="$CONFIG_DIR/neo4j/run/neo4j.pid"

# If Neo4j is not running, restart it
if ! pgrep -x "java" | grep -q "neo4j"; then
    echo "Starting Neo4j..."

    # If stale PID file exists, remove it
    if [ -f "$NEO4J_PID_FILE" ]; then
        echo "Removing stale Neo4j PID file..."
        rm -f "$NEO4J_PID_FILE"
    fi

    # Start Neo4j
    neo4j start > /dev/null 2>&1
    sleep 5
    done_msg "Starting Neo4j"
else
    echo "Neo4j is already running!"
fi

# --- Check & Start ArangoDB ---
ARANGO_PID_FILE="$CONFIG_DIR/arangodb3/arangod.pid"

if pgrep -x "arangod" > /dev/null; then
    echo "ArangoDB is already running!"
else
    echo "Starting ArangoDB..."

    # A container that was killed rather than stopped leaves the pid file behind
    if [ -f "$ARANGO_PID_FILE" ]; then
        echo "Removing stale ArangoDB PID file..."
        rm -f "$ARANGO_PID_FILE"
    fi

    arangod --configuration /etc/arangodb3/arangod.conf \
            --daemon --pid-file "$ARANGO_PID_FILE" > /dev/null 2>&1
    sleep 5
    done_msg "Starting ArangoDB"
fi

# --- Check & Start ChromaDB ---
# Tracked by pid file rather than pgrep: "chroma run" is a plain python command
# line, so a pattern match would also hit any shell that merely mentions it.
CHROMA_PID_FILE="$CONFIG_DIR/chroma/chroma.pid"

if [ -f "$CHROMA_PID_FILE" ] && kill -0 "$(cat "$CHROMA_PID_FILE")" 2> /dev/null; then
    echo "ChromaDB is already running!"
else
    echo "Starting ChromaDB..."
    nohup chroma run --path "$CONFIG_DIR/chroma" --host 0.0.0.0 --port 8000 \
        > "$CONFIG_DIR/chroma/chroma.log" 2>&1 &
    echo $! > "$CHROMA_PID_FILE"
    sleep 5
    done_msg "Starting ChromaDB"
fi

exec "$@"
