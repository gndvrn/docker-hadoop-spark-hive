#!/bin/bash

set -e

LIMA_INSTANCE="hadoop-cluster-vm"
PROJECT_DIR="$(pwd)"
SCRIPTS_DIR="${PROJECT_DIR}/scripts"

print_header() {
    echo ""
    echo "=========================================="
    echo "$1"
    echo "=========================================="
    echo ""
}

print_logo() {
    clear
    echo ""
    echo "╔═══════════════════════════════════════════════════════╗"
    echo "║                                                       ║"
    echo "║     Hadoop + Spark + Hive Cluster Manager            ║"
    echo "║                                                       ║"
    echo "╚═══════════════════════════════════════════════════════╝"
    echo ""
}

print_menu() {
    echo "Выберите действие:"
    echo ""
    echo "  1) 🚀 Быстрый старт (Quick Start)"
    echo "     └─ Полная инициализация кластера"
    echo ""
    echo "  2) ▶️  Запустить кластер (Start)"
    echo "     └─ Запуск существующего кластера"
    echo ""
    echo "  3) 🔄 Перезапустить кластер (Restart)"
    echo "     └─ Перезапуск всех сервисов"
    echo ""
    echo "  4) ⏹️  Остановить кластер (Stop)"
    echo "     └─ Остановка контейнеров и Lima VM"
    echo ""
    echo "  5) 📊 Статус кластера (Status)"
    echo "     └─ Информация о состоянии системы"
    echo ""
    echo "  6) 📝 Логи (Logs)"
    echo "     └─ Просмотр логов контейнеров"
    echo ""
    echo "  7) 🖥️  Вход в Lima VM (Shell)"
    echo "     └─ Доступ к командной строке VM"
    echo ""
    echo "  8) 🌐 Список URL сервисов (URLs)"
    echo "     └─ Показать все точки доступа"
    echo ""
    echo "  9) 🗑️  Полная очистка (Clean All)"
    echo "     └─ Удалить VM и все данные"
    echo ""
    echo "  0) ❌ Выход (Exit)"
    echo ""
}

check_lima() {
    if ! command -v limactl &> /dev/null; then
        echo "❌ ERROR: limactl не установлен."
        echo "Установите Lima: brew install lima"
        exit 1
    fi
}

check_vm_exists() {
    if ! limactl list 2>/dev/null | grep -q "^${LIMA_INSTANCE}"; then
        return 1
    fi
    return 0
}

get_vm_status() {
    if check_vm_exists; then
        limactl list ${LIMA_INSTANCE} 2>/dev/null | tail -n 1 | awk '{print $2}'
    else
        echo "NotExist"
    fi
}

check_containers_running() {
    if [ "$(get_vm_status)" != "Running" ]; then
        return 1
    fi
    
    local containers_count=$(limactl shell ${LIMA_INSTANCE} bash <<'EOF'
newgrp docker <<DOCKER_EOF
cd "${PROJECT_DIR:-$(pwd)}"
docker compose ps --status running 2>/dev/null | grep -v "^NAME" | wc -l
DOCKER_EOF
EOF
)
    
    if [ "$containers_count" -gt 0 ]; then
        return 0
    else
        return 1
    fi
}

get_cluster_status() {
    local vm_status=$(get_vm_status)
    
    if [ "$vm_status" = "NotExist" ]; then
        echo "not_initialized"
    elif [ "$vm_status" = "Running" ]; then
        if check_containers_running; then
            echo "running"
        else
            echo "vm_running_no_containers"
        fi
    else
        echo "stopped"
    fi
}

reinit_hdfs_disks() {
    
    
    echo "Переинициализация HDFS виртуальных дисков..."
    limactl shell ${LIMA_INSTANCE} bash <<'EOF'
# Unmount existing disks
sudo umount /mnt/dn1 2>/dev/null || true
sudo umount /mnt/dn2 2>/dev/null || true
sudo umount /mnt/dn3 2>/dev/null || true

# Remove loop devices
sudo losetup -D

# Remove old directories and images
sudo rm -rf /mnt/dn1 /mnt/dn2 /mnt/dn3
sudo rm -f /mnt/dn1.img /mnt/dn2.img /mnt/dn3.img

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

echo "HDFS диски созданы и примонтированы:"
df -h /mnt/dn1 /mnt/dn2 /mnt/dn3
EOF
    echo "✅ HDFS диски переинициализированы!"
}

quick_start() {
    print_header "🚀 Запуск Quick Start..."
    
    local cluster_status=$(get_cluster_status)
    
    if [ "$cluster_status" = "running" ]; then
        echo "❌ Кластер уже работает!"
        echo ""
        echo "Если вы хотите остановить кластер, используйте опцию 4 (Остановить кластер)."
        pause
        return
    elif [ "$cluster_status" = "stopped" ] || [ "$cluster_status" = "vm_running_no_containers" ]; then
        echo "❌ Кластер уже существует и остановлен."
        echo ""
        echo "Выберите одно из действий:"
        echo "  - Опция 2: Запустить существующий кластер"
        echo "  - Опция 9: Полная очистка, после чего можно выполнить Quick Start"
        pause
        return
    fi
    
    bash "${SCRIPTS_DIR}/quick-start.sh"
    echo ""
    echo "✅ Кластер успешно инициализирован!"
    pause
}

start_cluster() {
    print_header "▶️  Запуск кластера..."
    
    if ! check_vm_exists; then
        echo "❌ Lima VM '${LIMA_INSTANCE}' не существует."
        echo "Используйте опцию 1 (Quick Start) для первоначальной настройки."
        pause
        return
    fi
    
    local vm_status=$(get_vm_status)
    
    if [ "$vm_status" = "Running" ] && check_containers_running; then
        echo "❌ Кластер уже работает!"
        pause
        return
    fi
    
    if [ "$vm_status" != "Running" ]; then
        echo "Запуск Lima VM '${LIMA_INSTANCE}'..."
        limactl start ${LIMA_INSTANCE}
        echo "✅ Lima VM запущена."
        echo ""
    fi
    
    reinit_hdfs_disks
    echo ""
    
    echo "Запуск Docker контейнеров..."
    limactl shell ${LIMA_INSTANCE} bash <<EOF
newgrp docker <<DOCKER_EOF
cd "${PROJECT_DIR}"
docker compose up -d
DOCKER_EOF
EOF
    
    echo ""
    echo "✅ Кластер успешно запущен!"
    pause
}

restart_cluster() {
    print_header "🔄 Перезапуск кластера..."
    
    if ! check_vm_exists; then
        echo "❌ Lima VM '${LIMA_INSTANCE}' не существует."
        echo "Используйте опцию 1 (Quick Start) для первоначальной настройки."
        pause
        return
    fi
    
    local vm_status=$(get_vm_status)
    
    if [ "$vm_status" != "Running" ]; then
        echo "❌ Lima VM не запущена."
        echo "Используйте опцию 2 (Запустить кластер) для запуска остановленного кластера."
        pause
        return
    fi
    
    if ! check_containers_running; then
        echo "⚠️  Контейнеры не работают. Запускаем их..."
        reinit_hdfs_disks
        echo ""
        limactl shell ${LIMA_INSTANCE} bash <<EOF
newgrp docker <<DOCKER_EOF
cd "${PROJECT_DIR}"
docker compose up -d
DOCKER_EOF
EOF
        echo ""
        echo "✅ Кластер успешно запущен!"
        pause
        return
    fi
    
    echo "Остановка Docker контейнеров..."
    limactl shell ${LIMA_INSTANCE} bash <<EOF
newgrp docker <<DOCKER_EOF
cd "${PROJECT_DIR}"
docker compose down
DOCKER_EOF
EOF
    
    echo ""
    sleep 2
    
    reinit_hdfs_disks
    echo ""
    
    echo "Запуск Docker контейнеров..."
    limactl shell ${LIMA_INSTANCE} bash <<EOF
newgrp docker <<DOCKER_EOF
cd "${PROJECT_DIR}"
docker compose up -d
DOCKER_EOF
EOF
    
    echo ""
    echo "✅ Кластер успешно перезапущен!"
    pause
}

stop_cluster() {
    print_header "⏹️  Остановка кластера..."
    
    if ! check_vm_exists; then
        echo "❌ Lima VM '${LIMA_INSTANCE}' не существует."
        pause
        return
    fi
    
    local vm_status=$(get_vm_status)
    
    if [ "$vm_status" != "Running" ]; then
        echo "⚠️  Lima VM уже остановлена."
        pause
        return
    fi
    
    echo "Остановка Docker контейнеров..."
    limactl shell ${LIMA_INSTANCE} bash <<EOF
newgrp docker <<DOCKER_EOF
cd "${PROJECT_DIR}"
docker compose down
DOCKER_EOF
EOF
    
    echo ""
    echo "Остановка Lima VM..."
    limactl stop ${LIMA_INSTANCE}
    
    echo ""
    echo "✅ Кластер остановлен!"
    pause
}

show_status() {
    print_header "📊 Статус кластера"
    
    VM_STATUS=$(get_vm_status)
    
    echo "Lima VM Status: ${VM_STATUS}"
    echo ""
    
    if [ "$VM_STATUS" = "Running" ]; then
        echo "Docker Containers:"
        echo "─────────────────────────────────────────"
        limactl shell ${LIMA_INSTANCE} bash <<'EOF'
newgrp docker <<DOCKER_EOF
cd "${PROJECT_DIR:-$(pwd)}"
docker compose ps
DOCKER_EOF
EOF
        echo ""
        echo "HDFS Disk Usage:"
        echo "─────────────────────────────────────────"
        limactl shell ${LIMA_INSTANCE} bash <<'EOF'
df -h /mnt/dn1 /mnt/dn2 /mnt/dn3 2>/dev/null || echo "HDFS disks not mounted"
EOF
    elif [ "$VM_STATUS" = "NotExist" ]; then
        echo "❌ Lima VM не создана. Запустите Quick Start (опция 1)."
    else
        echo "⚠️  Lima VM остановлена. Запустите кластер (опция 2)."
    fi
    
    echo ""
    pause
}

show_logs() {
    print_header "📝 Просмотр логов"
    
    VM_STATUS=$(get_vm_status)
    
    if [ "$VM_STATUS" != "Running" ]; then
        echo "❌ Lima VM не запущена."
        pause
        return
    fi
    
    echo "Доступные контейнеры:"
    echo "  1) namenode"
    echo "  2) datanode1"
    echo "  3) datanode2"
    echo "  4) datanode3"
    echo "  5) resourcemanager"
    echo "  6) nodemanager1"
    echo "  7) nodemanager2"
    echo "  8) nodemanager3"
    echo "  9) hive-server"
    echo " 10) hive-metastore"
    echo " 11) hive-metastore-postgresql"
    echo " 12) spark-yarn"
    echo " 13) Все контейнеры (all)"
    echo "  0) Назад"
    echo ""
    read -p "Выберите контейнер: " log_choice
    
    case $log_choice in
        1) CONTAINER="namenode" ;;
        2) CONTAINER="datanode1" ;;
        3) CONTAINER="datanode2" ;;
        4) CONTAINER="datanode3" ;;
        5) CONTAINER="resourcemanager" ;;
        6) CONTAINER="nodemanager1" ;;
        7) CONTAINER="nodemanager2" ;;
        8) CONTAINER="nodemanager3" ;;
        9) CONTAINER="hive-server" ;;
        10) CONTAINER="hive-metastore" ;;
        11) CONTAINER="hive-metastore-postgresql" ;;
        12) CONTAINER="spark-yarn" ;;
        13) CONTAINER="" ;;
        0) return ;;
        *) echo "Неверный выбор"; pause; return ;;
    esac
    
    echo ""
    echo "Нажмите Ctrl+C для выхода из режима просмотра логов"
    echo ""
    sleep 2
    
    limactl shell ${LIMA_INSTANCE} bash <<EOF
newgrp docker <<DOCKER_EOF
cd "${PROJECT_DIR}"
if [ -z "${CONTAINER}" ]; then
    docker compose logs -f
else
    docker compose logs -f ${CONTAINER}
fi
DOCKER_EOF
EOF
}

enter_shell() {
    print_header "🖥️  Вход в Lima VM Shell"
    
    VM_STATUS=$(get_vm_status)
    
    if [ "$VM_STATUS" != "Running" ]; then
        echo "❌ Lima VM не запущена."
        pause
        return
    fi
    
    echo "Подключение к Lima VM..."
    echo "Используйте 'newgrp docker' для доступа к Docker командам"
    echo "Используйте 'exit' для выхода"
    echo ""
    limactl shell ${LIMA_INSTANCE}
}

show_urls() {
    print_header "🌐 URL Сервисов"
    
    VM_STATUS=$(get_vm_status)
    
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║  Service                  │  URL                              ║"
    echo "╠═══════════════════════════════════════════════════════════════╣"
    echo "║  NameNode UI              │  http://localhost:9870           ║"
    echo "║  ResourceManager UI       │  http://localhost:8088           ║"
    echo "║  HiveServer2 UI           │  http://localhost:10002          ║"
    echo "║  JupyterLab               │  http://localhost:8888           ║"
    echo "║  DataNode 1               │  http://localhost:9860           ║"
    echo "║  DataNode 2               │  http://localhost:9861           ║"
    echo "║  DataNode 3               │  http://localhost:9862           ║"
    echo "║  NodeManager 1            │  http://localhost:8043           ║"
    echo "║  NodeManager 2            │  http://localhost:8044           ║"
    echo "║  NodeManager 3            │  http://localhost:8045           ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    
    if [ "$VM_STATUS" != "Running" ]; then
        echo ""
        echo "⚠️  Lima VM не запущена. URL будут доступны после запуска кластера."
    fi
    
    echo ""
    pause
}

clean_all() {
    print_header "🗑️  Полная очистка"
    
    echo "⚠️  ВНИМАНИЕ: Это удалит Lima VM и все данные!"
    echo ""
    read -p "Вы уверены? Введите 'yes' для подтверждения: " confirm
    
    if [ "$confirm" != "yes" ]; then
        echo "Отменено."
        pause
        return
    fi
    
    echo ""
    echo "Остановка и удаление Lima VM..."
    
    if check_vm_exists; then
        limactl stop ${LIMA_INSTANCE} 2>/dev/null || true
        limactl delete ${LIMA_INSTANCE}
        echo "✅ Lima VM удалена."
    else
        echo "Lima VM не существует."
    fi
    
    echo ""
    pause
}

pause() {
    echo ""
    read -p "Нажмите Enter для продолжения..."
}

main_menu() {
    while true; do
        print_logo
        print_menu
        
        read -p "Введите номер опции: " choice
        
        case $choice in
            1) quick_start ;;
            2) start_cluster ;;
            3) restart_cluster ;;
            4) stop_cluster ;;
            5) show_status ;;
            6) show_logs ;;
            7) enter_shell ;;
            8) show_urls ;;
            9) clean_all ;;
            0) 
                print_header "👋 До свидания!"
                exit 0
                ;;
            *)
                echo "❌ Неверный выбор. Попробуйте снова."
                pause
                ;;
        esac
    done
}

check_lima
main_menu
