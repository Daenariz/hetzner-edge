#!/usr/env/bin bash

if [ $# -ne 1 ]; then
    echo "Usage: mc-bkp <instance>"
    echo "Example: mc-bkp survival"
    exit 1
fi

INSTANCE="$1"
SERVICE_NAME="minecraft-server-${INSTANCE}.service"
SOURCE_DIR="/srv/minecraft/${INSTANCE}/world"
BACKUP_DIR="/data/minecraft/backups/${INSTANCE}/worlds"
TIMESTAMP=$(date +"%Y_%m_%d-%H_%M_%S")
BACKUP_FILE="world.${TIMESTAMP}.tar.gz"

TIMEOUT=60

wait_for_service_state() {
    local service="$1"
    local desired_state="$2"
    local elapsed=0

    echo "Waiting for ${service} to become '${desired_state}' (timeout: ${TIMEOUT}s)..."

    while [ $elapsed -lt $TIMEOUT ]; do
        local current_state
        current_state=$(systemctl is-active "$service" 2>/dev/null || true)

        if [ "$current_state" = "$desired_state" ]; then
            echo "${service} is '${desired_state}' after ${elapsed}s."
            return 0
        fi

        sleep 1
        ((elapsed++))
    done

    echo "Error: ${service} did not reach '${desired_state}' within ${TIMEOUT}s (current: ${current_state})."
    return 1
}


if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: Source directory '${SOURCE_DIR}' does not exist."
    exit 1
fi

echo "Stopping ${SERVICE_NAME}..."
systemctl stop "$SERVICE_NAME"
wait_for_service_state "$SERVICE_NAME" "inactive"

echo "Archiving '${SOURCE_DIR}' to '${BACKUP_DIR}/${BACKUP_FILE}'..."
mkdir -p "$BACKUP_DIR"
tar -czf "${BACKUP_DIR}/${BACKUP_FILE}" -C "$(dirname "$SOURCE_DIR")" "$(basename "$SOURCE_DIR")"

echo "Backup created: ${BACKUP_DIR}/${BACKUP_FILE}"
echo "Backup size: $(du -h "${BACKUP_DIR}/${BACKUP_FILE}" | cut -f1)"

echo "Starting ${SERVICE_NAME}..."
systemctl start "$SERVICE_NAME"
wait_for_service_state "$SERVICE_NAME" "active"

echo "Done."
