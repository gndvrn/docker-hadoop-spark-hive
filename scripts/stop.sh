#!/bin/bash

set -e

echo "==================================="
echo "Stopping Hadoop-Spark-Hive Cluster"
echo "==================================="

LIMA_INSTANCE="hadoop-cluster-vm"
PROJECT_DIR="$(pwd)"

if ! limactl list | grep -q "^${LIMA_INSTANCE}"; then
    echo "Lima VM '${LIMA_INSTANCE}' does not exist."
    exit 0
fi

VM_STATUS=$(limactl list ${LIMA_INSTANCE} | tail -n 1 | awk '{print $2}')

if [ "$VM_STATUS" = "Running" ]; then
    echo ""
    echo "Stopping Docker containers..."
    
    limactl shell ${LIMA_INSTANCE} bash <<EOF
newgrp docker <<DOCKER_EOF
cd "${PROJECT_DIR}"
docker compose down
DOCKER_EOF
EOF
    
    echo ""
    echo "Stopping Lima VM..."
    limactl stop ${LIMA_INSTANCE}
    
    echo ""
    echo "==================================="
    echo "Cluster stopped successfully!"
    echo "==================================="
    echo ""
    echo "To start again, use './manage.sh' and select option 2 (Start)."
else
    echo "Lima VM '${LIMA_INSTANCE}' is already stopped (status: ${VM_STATUS})."
fi
