#!/bin/bash

set -e

echo "==================================="
echo "Starting Hadoop-Spark-Hive Cluster"
echo "==================================="

LIMA_INSTANCE="hadoop-cluster-vm"
PROJECT_DIR="$(pwd)"

if ! command -v limactl &> /dev/null; then
    echo "ERROR: limactl is not installed. Please install Lima first."
    echo "Install with: brew install lima"
    exit 1
fi

if ! limactl list | grep -q "^${LIMA_INSTANCE}"; then
    echo "ERROR: Lima VM '${LIMA_INSTANCE}' does not exist."
    echo "Please run './manage.sh' and use Quick Start (option 1) to set up the cluster."
    exit 1
fi

VM_STATUS=$(limactl list ${LIMA_INSTANCE} | tail -n 1 | awk '{print $2}')

if [ "$VM_STATUS" != "Running" ]; then
    echo "Starting Lima VM '${LIMA_INSTANCE}'..."
    limactl start ${LIMA_INSTANCE}
    echo "Lima VM started successfully."
    echo ""
fi

echo "Reinitializing HDFS virtual disks..."
limactl shell ${LIMA_INSTANCE} bash <<'EOF'
sudo umount /mnt/dn1 2>/dev/null || true
sudo umount /mnt/dn2 2>/dev/null || true
sudo umount /mnt/dn3 2>/dev/null || true

sudo losetup -D

sudo rm -rf /mnt/dn1 /mnt/dn2 /mnt/dn3
sudo rm -f /mnt/dn1.img /mnt/dn2.img /mnt/dn3.img

sudo mkdir -p /mnt/dn1 /mnt/dn2 /mnt/dn3

sudo dd if=/dev/zero of=/hdfs_dn1.img bs=1G count=0 seek=5
sudo dd if=/dev/zero of=/hdfs_dn2.img bs=1G count=0 seek=5
sudo dd if=/dev/zero of=/hdfs_dn3.img bs=1G count=0 seek=5

sudo mv /hdfs_dn1.img /mnt/dn1.img
sudo mv /hdfs_dn2.img /mnt/dn2.img
sudo mv /hdfs_dn3.img /mnt/dn3.img

sudo losetup -fP /mnt/dn1.img
sudo losetup -fP /mnt/dn2.img
sudo losetup -fP /mnt/dn3.img

sudo mkfs.ext4 -F /dev/loop0
sudo mkfs.ext4 -F /dev/loop1
sudo mkfs.ext4 -F /dev/loop2

sudo mount /dev/loop0 /mnt/dn1
sudo mount /dev/loop1 /mnt/dn2
sudo mount /dev/loop2 /mnt/dn3

echo "HDFS disks created and mounted successfully:"
df -h /mnt/dn1 /mnt/dn2 /mnt/dn3
EOF

echo ""
echo "Starting Docker containers..."
limactl shell ${LIMA_INSTANCE} bash <<EOF
newgrp docker <<DOCKER_EOF
cd "${PROJECT_DIR}"
docker compose up -d
DOCKER_EOF
EOF

echo ""
echo "==================================="
echo "Cluster started successfully!"
echo "==================================="
echo ""
echo "Checking container status..."
limactl shell ${LIMA_INSTANCE} bash <<EOF
newgrp docker <<DOCKER_EOF
cd "${PROJECT_DIR}"
docker compose ps
DOCKER_EOF
EOF

echo ""
echo "==================================="
echo "Access Points:"
echo "==================================="
echo "  - NameNode UI:        http://localhost:9870"
echo "  - ResourceManager UI: http://localhost:8088"
echo "  - HiveServer2 UI:     http://localhost:10002"
echo "  - JupyterLab:         http://localhost:8888"
echo "==================================="
