#!/bin/bash

set -e

echo "==================================="
echo "Quick Start Script for Hadoop-Spark-Hive"
echo "==================================="

# Load versions from settings.env
source settings.env

DOWNLOADS_DIR="./downloads"
LIMA_INSTANCE="hadoop-cluster-vm"
PROJECT_DIR="$(pwd)"

# Check if limactl is installed
if ! command -v limactl &> /dev/null; then
    echo "ERROR: limactl is not installed. Please install Lima first."
    echo "Install with: brew install lima"
    exit 1
fi

# Create downloads directory if it doesn't exist
mkdir -p ${DOWNLOADS_DIR}

echo ""
echo "Checking and downloading required source archives..."
echo ""

# Hadoop
HADOOP_FILE="hadoop-${HADOOP_VERSION}.tar.gz"
HADOOP_URL="https://downloads.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/${HADOOP_FILE}"
if [ ! -f "${DOWNLOADS_DIR}/${HADOOP_FILE}" ]; then
    echo "Downloading Hadoop ${HADOOP_VERSION}..."
    wget ${HADOOP_URL} -O ${DOWNLOADS_DIR}/${HADOOP_FILE}
    echo "Hadoop downloaded successfully."
else
    echo "Hadoop ${HADOOP_VERSION} already exists. Skipping download."
fi

# Spark
SPARK_FILE="spark-${SPARK_VERSION}-bin-hadoop3.tgz"
SPARK_URL="https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/${SPARK_FILE}"
if [ ! -f "${DOWNLOADS_DIR}/${SPARK_FILE}" ]; then
    echo "Downloading Spark ${SPARK_VERSION}..."
    wget ${SPARK_URL} -O ${DOWNLOADS_DIR}/${SPARK_FILE}
    echo "Spark downloaded successfully."
else
    echo "Spark ${SPARK_VERSION} already exists. Skipping download."
fi

# PySpark
PYSPARK_FILE="pyspark-${SPARK_VERSION}.tar.gz"
PYSPARK_URL="https://files.pythonhosted.org/packages/source/p/pyspark/${PYSPARK_FILE}"
if [ ! -f "${DOWNLOADS_DIR}/${PYSPARK_FILE}" ]; then
    echo "Downloading PySpark ${SPARK_VERSION}..."
    wget ${PYSPARK_URL} -O ${DOWNLOADS_DIR}/${PYSPARK_FILE}
    echo "PySpark downloaded successfully."
else
    echo "PySpark ${SPARK_VERSION} already exists. Skipping download."
fi

# Hive
HIVE_FILE="apache-hive-${HIVE_VERSION}-bin.tar.gz"
HIVE_URL="https://downloads.apache.org/hive/hive-${HIVE_VERSION}/${HIVE_FILE}"
if [ ! -f "${DOWNLOADS_DIR}/${HIVE_FILE}" ]; then
    echo "Downloading Hive ${HIVE_VERSION}..."
    wget ${HIVE_URL} -O ${DOWNLOADS_DIR}/${HIVE_FILE}
    echo "Hive downloaded successfully."
else
    echo "Hive ${HIVE_VERSION} already exists. Skipping download."
fi

echo ""
echo "All required archives are ready!"
echo ""

# Check if Lima VM instance exists
echo "==================================="
echo "Checking Lima VM instance..."
echo "==================================="

if limactl list | grep -q "^${LIMA_INSTANCE}"; then
    echo "ERROR: Lima VM '${LIMA_INSTANCE}' already exists."
    echo "This script is for initial cluster setup only."
    echo ""
    echo "Please use the manage.sh menu instead:"
    echo "  - Option 2: Start existing cluster"
    echo "  - Option 9: Clean all, then you can run Quick Start"
    exit 1
else
    echo "Lima VM '${LIMA_INSTANCE}' does not exist. Creating new VM..."
    
    # Create Lima configuration file
    cat > /tmp/lima-hadoop.yaml <<EOF
images:
  - location: "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-arm64.qcow2"
    arch: "aarch64"
arch: "aarch64"
cpus: 6
memory: "6GiB"
disk: "40GiB"
mounts:
  - location: "${PROJECT_DIR}"
    writable: true
ssh:
  localPort: 0
  loadDotSSHPubKeys: true
containerd:
  system: false
  user: false
EOF

    echo "Creating Lima VM with 6 CPUs, 6GB RAM, 40GB disk..."
    limactl start --name=${LIMA_INSTANCE} /tmp/lima-hadoop.yaml
    rm /tmp/lima-hadoop.yaml
    
    echo ""
    echo "Installing Docker and Docker Compose in Lima VM..."
    limactl shell ${LIMA_INSTANCE} bash <<'EOF'
# Update package list
sudo apt-get update

# Install prerequisites
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add user to docker group
sudo usermod -aG docker $USER

# Enable and start Docker
sudo systemctl enable docker
sudo systemctl start docker

echo "Docker installed successfully!"
docker --version
docker compose version
EOF

    echo ""
    echo "Creating HDFS virtual disks..."
    limactl shell ${LIMA_INSTANCE} bash <<'EOF'
# Create mount directories
sudo mkdir -p /mnt/dn1 /mnt/dn2 /mnt/dn3

# Create 5GB sparse image files
sudo dd if=/dev/zero of=/hdfs_dn1.img bs=1G count=0 seek=5
sudo dd if=/dev/zero of=/hdfs_dn2.img bs=1G count=0 seek=5
sudo dd if=/dev/zero of=/hdfs_dn3.img bs=1G count=0 seek=5

# Move images to /mnt
sudo mv /hdfs_dn1.img /mnt/dn1.img
sudo mv /hdfs_dn2.img /mnt/dn2.img
sudo mv /hdfs_dn3.img /mnt/dn3.img

# Attach as loop devices
sudo losetup -fP /mnt/dn1.img
sudo losetup -fP /mnt/dn2.img
sudo losetup -fP /mnt/dn3.img

# Format with ext4
sudo mkfs.ext4 -F /dev/loop0
sudo mkfs.ext4 -F /dev/loop1
sudo mkfs.ext4 -F /dev/loop2

# Mount the disks
sudo mount /dev/loop0 /mnt/dn1
sudo mount /dev/loop1 /mnt/dn2
sudo mount /dev/loop2 /mnt/dn3

echo "HDFS disks created and mounted successfully:"
df -h /mnt/dn1 /mnt/dn2 /mnt/dn3
EOF

fi

echo ""
echo "==================================="
echo "Building Docker images inside Lima VM..."
echo "==================================="

limactl shell ${LIMA_INSTANCE} bash <<EOF
newgrp docker <<DOCKER_EOF
cd "${PROJECT_DIR}"
docker build --no-cache -t hadoop-core:latest -f ./hadoop-core/Dockerfile .
DOCKER_EOF
EOF

echo ""
echo "==================================="
echo "Starting all containers..."
echo "==================================="

limactl shell ${LIMA_INSTANCE} bash <<EOF
newgrp docker <<DOCKER_EOF
cd "${PROJECT_DIR}"
docker compose up -d
DOCKER_EOF
EOF

echo ""
echo "==================================="
echo "All done! Containers are starting..."
echo "==================================="
echo ""
echo "Useful commands:"
echo "  - Enter VM: limactl shell ${LIMA_INSTANCE}"
echo "  - Check status: limactl shell ${LIMA_INSTANCE} docker compose ps"
echo "  - View logs: limactl shell ${LIMA_INSTANCE} docker compose logs -f"
echo "  - Stop all: limactl shell ${LIMA_INSTANCE} docker compose down"
echo "  - Stop VM: limactl stop ${LIMA_INSTANCE}"
echo "==================================="
