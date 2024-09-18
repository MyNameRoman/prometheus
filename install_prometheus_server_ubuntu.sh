#!/bin/bash
#--------------------------------------------------------------------
# Script to Install Prometheus Server on Linux Ubuntu
# Tested on Ubuntu 22.04, 24.04
# Developed by Denis Astahov in 2024
#--------------------------------------------------------------------

# Указываем версию Prometheus
PROMETHEUS_VERSION="2.54.1"

PROMETHEUS_FOLDER_CONFIG="/etc/prometheus"
PROMETHEUS_FOLDER_TSDATA="/etc/prometheus/data"

# Загружаем Prometheus из официального репозитория
cd /tmp
wget https://github.com/prometheus/prometheus/releases/download/v$PROMETHEUS_VERSION/prometheus-$PROMETHEUS_VERSION.linux-amd64.tar.gz
if [ $? -ne 0 ]; then
  echo "Ошибка при загрузке Prometheus. Проверьте URL или доступность интернета."
  exit 1
fi

# Распаковываем архив
tar xvfz prometheus-$PROMETHEUS_VERSION.linux-amd64.tar.gz
cd prometheus-$PROMETHEUS_VERSION.linux-amd64

# Переносим бинарный файл в /usr/bin
mv prometheus /usr/bin/
rm -rf /tmp/prometheus*

# Создаем необходимые каталоги
mkdir -p $PROMETHEUS_FOLDER_CONFIG
mkdir -p $PROMETHEUS_FOLDER_TSDATA

# Конфигурация Prometheus
cat <<EOF> $PROMETHEUS_FOLDER_CONFIG/prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name      : "prometheus"
    static_configs:
      - targets: ["localhost:9090"]
EOF

# Создаем пользователя для Prometheus
useradd -rs /bin/false prometheus

# Устанавливаем права на файлы и директории
chown prometheus:prometheus /usr/bin/prometheus
chown prometheus:prometheus $PROMETHEUS_FOLDER_CONFIG
chown prometheus:prometheus $PROMETHEUS_FOLDER_CONFIG/prometheus.yml
chown prometheus:prometheus $PROMETHEUS_FOLDER_TSDATA

# Создаем systemd-сервис для управления Prometheus
cat <<EOF> /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus Server
After=network.target

[Service]
User=prometheus
Group=prometheus
Type=simple
Restart=on-failure
ExecStart=/usr/bin/prometheus \
  --config.file       ${PROMETHEUS_FOLDER_CONFIG}/prometheus.yml \
  --storage.tsdb.path ${PROMETHEUS_FOLDER_TSDATA}

[Install]
WantedBy=multi-user.target
EOF

# Перезапускаем systemd и включаем сервис Prometheus
systemctl daemon-reload
systemctl start prometheus
systemctl enable prometheus

# Проверка статуса Prometheus
systemctl status prometheus --no-pager

# Вывод версии Prometheus
prometheus --version
