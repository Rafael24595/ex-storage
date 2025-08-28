#!/bin/bash

LOG_DIR="./log"

if [ ! -d "$LOG_DIR" ]; then
    echo "The logs folder doesn't exist."
    exit 0
fi

TOTAL=$(find "$LOG_DIR" -mindepth 1 | wc -l)
if [ "$TOTAL" -eq 0 ]; then
    echo "No logs to remove. Exiting..."
    exit 0
fi

if ! find "$LOG_DIR" -mindepth 1 -delete; then
    echo "The logs cannot be removed."
    exit $REMOVE_EXIT_CODE
fi

echo "Items removed: ${TOTAL}."