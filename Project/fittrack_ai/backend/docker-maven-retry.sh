#!/bin/sh
set -eu

max_attempts="${MAVEN_MAX_ATTEMPTS:-5}"
retry_delay="${MAVEN_RETRY_DELAY_SECONDS:-10}"
attempt=1

while true; do
    if mvn -B -ntp -U "$@"; then
        exit 0
    fi

    if [ "$attempt" -ge "$max_attempts" ]; then
        echo "Maven failed after ${attempt} attempts." >&2
        exit 1
    fi

    wait_seconds=$((retry_delay * attempt))
    echo "Maven attempt ${attempt} failed; retrying in ${wait_seconds}s..." >&2
    sleep "$wait_seconds"
    attempt=$((attempt + 1))
done
