#!/bin/bash
set -e

DB_DIR="/home/bappa/Rentzy/db_data"
PORT=5433

if [ ! -f "$DB_DIR/PG_VERSION" ]; then
    echo "Initializing database cluster in $DB_DIR..."
    initdb -D "$DB_DIR" --auth=trust
else
    echo "Database cluster already initialized."
fi

# Check if PostgreSQL is already running on port 5433
if pg_isready -h 127.0.0.1 -p $PORT > /dev/null 2>&1; then
    echo "PostgreSQL is already running on port $PORT."
else
    echo "Starting PostgreSQL on port $PORT..."
    pg_ctl -D "$DB_DIR" -l "$DB_DIR/logfile" -o "-p $PORT -k $DB_DIR" start
    
    # Wait for it to start
    echo "Waiting for PostgreSQL to start..."
    for i in {1..10}; do
        if pg_isready -h 127.0.0.1 -p $PORT > /dev/null 2>&1; then
            echo "PostgreSQL is running."
            break
        fi
        sleep 1
    done
fi
