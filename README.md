# Кластер Hadoop + Hive + Spark в Docker

Псевдо-распределенный кластер Apache Hadoop в Docker с Hive и Spark на YARN для локальной разработки и тестирования. Работает внутри Lima VM с выделенными виртуальными дисками для каждого HDFS DataNode для точного отображения дисковой емкости.

## Архитектура

**Кластер Hadoop HDFS:**
- 1 NameNode + 3 DataNodes
- YARN ResourceManager + 3 NodeManagers
- Фактор репликации: 1 (псевдо-распределенный режим)
- Каждый DataNode имеет выделенный виртуальный диск 5GB (устройство ext4 loop)

**Apache Hive:**
- HiveServer2 с метахранилищем PostgreSQL
- Предзагружен датасет NYC Taxi (~3 CSV файла)
- Движок выполнения MapReduce

**Apache Spark:**
- Spark на YARN (клиентский режим)
- JupyterLab с PySpark
- Включен пример notebook

## Требования

**Lima VM** требуется для правильного управления дисками HDFS:

```bash
# Установка Lima (macOS)
brew install lima
```

Lima предоставляет среду Linux VM, где контейнеры Docker работают с правильной изоляцией дисков для HDFS DataNodes.

## Быстрый старт

### Рекомендуемый способ: CLI панель управления

```bash
# Запустите интерактивную CLI панель управления
./manage.sh
```

CLI панель предоставляет удобный интерфейс для управления кластером:
- 🚀 Быстрый старт - полная инициализация кластера
- ▶️  Запуск/перезапуск кластера
- ⏹️  Остановка кластера
- 📊 Проверка статуса
- 📝 Просмотр логов
- 🖥️  Доступ к Lima VM shell
- 🌐 Список URL сервисов
- 🗑️  Полная очистка

### Альтернативный способ: Прямой запуск скриптов

```bash
# Первоначальная настройка (полная инициализация)
./scripts/quick-start.sh

# Остановка кластера
./scripts/stop.sh

# Перезапуск кластера
./scripts/restart.sh
```

**Что делает quick-start.sh:**
1. Загружает архивы Hadoop, Spark, Hive и PySpark
2. Создает или запускает Lima VM (`hadoop-cluster-vm`) с:
   - 6 CPUs, 6GB RAM, 40GB disk (aarch64)
   - Установленными Docker и Docker Compose
3. Создает 3x 5GB виртуальных дисков для HDFS DataNodes (`/mnt/dn1`, `/mnt/dn2`, `/mnt/dn3`)
4. Собирает Docker образы внутри VM
5. Запускает все контейнеры через `docker compose up -d`

**При повторных запусках:**
- Если VM существует: запускает ее, пересоздает виртуальные диски и запускает контейнеры
- Все данные HDFS сбрасываются для обеспечения чистого состояния

## Точки доступа

| Сервис | URL | Описание |
|---------|-----|-------------|
| NameNode UI | http://localhost:9870 | Обзор кластера HDFS |
| ResourceManager UI | http://localhost:8088 | Приложения и ресурсы YARN |
| HiveServer2 UI | http://localhost:10002 | Выполнение запросов Hive |
| JupyterLab | http://localhost:8888 | Spark notebooks (PySpark) |
| DataNode 1-3 | http://localhost:9860-9862 | Статистика отдельных DataNode |
| NodeManager 1-3 | http://localhost:8043-8045 | Ресурсы узлов YARN |

## Примеры использования

**HDFS:**
```bash
# Доступ через Lima VM shell
limactl shell hadoop-cluster-vm
docker exec -it namenode bash
hdfs dfs -ls /
hdfs dfs -put localfile.txt /user/data/

# Проверка использования диска DataNode
docker exec -it datanode1 df -h /hadoop/dfs/data
```

**Hive:**
```bash
# Доступ к Hive CLI
limactl shell hadoop-cluster-vm
docker exec -it hive-server bash
beeline -u jdbc:hive2://localhost:10000

# Запрос данных NYC taxi
SELECT * FROM nyc_taxi_data LIMIT 10;
```

**Spark (Jupyter):**
- Перейдите на http://localhost:8888
- Откройте `notebooks/spark-on-yarn-example.ipynb`
- Выполните ячейки для запуска заданий Spark на YARN

**Управление через CLI панель:**
```bash
# Запустите интерактивную панель управления
./manage.sh
```

**Прямое управление (альтернатива):**
```bash
# Остановить кластер
./scripts/stop.sh

# Перезапустить кластер
./scripts/restart.sh

# Полный сброс (пересоздает HDFS диски и образы)
./scripts/quick-start.sh

# Доступ к Lima VM shell
limactl shell hadoop-cluster-vm
newgrp docker

# Проверка статуса контейнеров (внутри VM после 'newgrp docker')
docker compose ps

# Просмотр логов (внутри VM после 'newgrp docker')
docker compose logs -f namenode

# Остановка Lima VM вручную
limactl stop hadoop-cluster-vm
```

## Структура проекта

```
.
├── manage.sh                    # CLI панель управления (рекомендуется)
├── scripts/                     # Директория со скриптами управления
│   ├── quick-start.sh          # Полная инициализация кластера
│   ├── start.sh                # Запуск существующего кластера
│   ├── restart.sh              # Перезапуск кластера
│   └── stop.sh                 # Остановка кластера
├── docker-compose.yml          # Конфигурация Docker Compose
├── settings.env                # Переменные окружения и версии
├── hadoop-namenode/            # Конфигурация NameNode
├── hadoop-datanode/            # Конфигурация DataNode
├── hadoop-resourcemanager/     # Конфигурация ResourceManager
├── hadoop-nodemanager/         # Конфигурация NodeManager
├── hadoop-hive/                # Конфигурация Hive
├── spark-yarn/                 # Конфигурация Spark on YARN
├── notebooks/                  # Jupyter notebooks с примерами
└── downloads/                  # Загруженные архивы (Hadoop, Spark, Hive)
```

## Компоненты

- **Hadoop**: 3.4.0
- **Hive**: 4.x
- **Spark**: 3.5.x
- **Python**: 3.11 (контейнер Jupyter)

## Данные

Датасет NYC Taxi автоматически загружается и загружается в HDFS во время сборки образа `hive-server`. Подробности см. в `hadoop-hive/load_nyc_taxi_data.sh`.

## Примечания

**Конфигурация Lima VM:**
- Эта установка работает внутри Lima VM для обеспечения правильной изоляции дисков для HDFS DataNodes
- Каждый DataNode использует выделенное устройство ext4 loop 5GB, смонтированное в `/mnt/dn1`, `/mnt/dn2`, `/mnt/dn3`
- Виртуальные диски пересоздаются при каждом запуске для обеспечения чистого состояния HDFS
- Настройки Lima VM: 6 CPUs, 6GB RAM, 40GB диск (можно изменить в `scripts/quick-start.sh`)

**Конфигурация ресурсов:**
- Лимиты ресурсов настроены для скромного оборудования (4GB RAM на NodeManager, 2 vCPUs)
- Настройте `settings.env` и `docker-compose.yml` по мере необходимости для вашей среды
- Для производственного использования рассмотрите увеличение ресурсов Lima VM и размеров дисков HDFS

**Проброс портов:**
- Все сервисы доступны через `localhost` благодаря автоматическому пробросу портов Lima
- Дополнительная конфигурация для доступа к веб-интерфейсам или API не требуется
