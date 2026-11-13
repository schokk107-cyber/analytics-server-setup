# Analytics Server Setup

Пошаговый набор скриптов для развёртывания Ubuntu VPS с Docker, ClickHouse 25.8, локальными ZIP-бэкапами и cron. Основан на ручной установке аналитического сервера EOS. **Это шаблон, а не протестированный на чистом VPS продукт.**

## Требования

- Чистая Ubuntu Server с `sudo`/root-доступом (исходная установка велась на Ubuntu 26.04).
- Доступ по SSH и аварийная консоль у хостера.
- Интернет для `apt` и Docker Hub.
- Рекомендуемые параметры исходной конфигурации: 2 vCPU, 4 GB RAM, 45 GB SSD/NVMe.

## Быстрый старт

```bash
cp config.env.example config.env
nano config.env
chmod 600 config.env
sudo ./install.sh
```

В меню выберите `1`, затем `2`, `3`, `4`, `5` или `all`. На **существующем** сервере не выбирайте `all`: этап установки ClickHouse намеренно отказывается перезаписывать `/opt/clickhouse/compose.yaml`.

## Что делают этапы

1. `01-system.sh`: обновляет индекс пакетов, устанавливает утилиты, `ssh`, `ufw`, `cron`; создаёт `analytics`, добавляет в `sudo`. **Не меняет SSH/firewall автоматически**. Выполните безопасные ручные шаги из [SECURITY.md](docs/SECURITY.md).
2. `02-docker.sh`: добавляет официальный репозиторий Docker для Ubuntu, устанавливает Docker Engine и Compose (если Docker отсутствует), включает службу.
3. `03-clickhouse.sh`: создаёт `/opt/clickhouse`, каталоги с UID/GID 101, генерирует пароль, устанавливает конфигурацию и запускает контейнер. Порты 8123 и 9000 слушают только `127.0.0.1`.
4. `04-backups.sh`: устанавливает скрипт `/usr/local/sbin/clickhouse-backup.sh`, задаёт ежедневное cron-задание в 03:00 UTC (настраивается), хранит последние 7 ZIP-архивов и проверяет свободное место перед созданием.
5. `05-verify.sh`: показывает состояние Docker, ClickHouse, баз, firewall, cron и диска.

## Проверка бэкапа и восстановления

Сначала запустите:

```bash
sudo /usr/local/sbin/clickhouse-backup.sh
sudo ls -lh /opt/clickhouse/backups
```

Для теста восстановления **в отдельную базу** используйте точное имя созданного ZIP-файла:

```bash
sudo docker exec clickhouse clickhouse-client --query "RESTORE DATABASE analytics AS analytics_restore_test FROM File('/backups/ИМЯ_АРХИВА.zip')"
sudo docker exec clickhouse clickhouse-client --query 'SHOW DATABASES'
sudo docker exec clickhouse clickhouse-client --query 'DROP DATABASE IF EXISTS analytics_restore_test'
```

Перед повторным тестом убедитесь, что тестовая база не существует. Не выполняйте `DROP DATABASE analytics`.

## Обслуживание

- Логи cron: `sudo tail -n 100 /var/log/clickhouse-backup.log` (появится после первого запуска по расписанию).
- Проверка времени: `timedatectl`; расписание использует UTC.
- Проверка места: `df -h /opt/clickhouse`.
- Управление ClickHouse: `cd /opt/clickhouse && sudo docker compose ps`.
- Настройки/секреты: `/opt/clickhouse/.env` (не коммитить).

## Ограничения и предостережения

- Бэкапы лежат на **том же VPS**. Они не защищают от потери диска или сервера. Нужна внешняя копия для полноценного disaster recovery.
- Скрипт проверяет минимум свободного места **перед** бэкапом, но не оценивает размер будущего архива. При росте базы увеличьте резерв и настройте мониторинг диска.
- Ротация оставляет 7 последних архивов с именем `analytics_*.zip`, не строго по календарным дням.
- Архив базы не включает `/opt/clickhouse/.env`, `compose.yaml` и конфигурацию сервера. Их нужно хранить отдельно, с защитой секретов.
- Не запускайте на рабочем сервере без просмотра скриптов и создания независимого бэкапа.
- Не тестировалось на чистом VPS; выполнена только статическая проверка синтаксиса и структуры проекта.

## GitHub

Создайте пустой репозиторий в GitHub и в каталоге проекта выполните:

```bash
git init
git add .
git commit -m "Initial analytics server setup"
git branch -M main
git remote add origin https://github.com/USERNAME/analytics-server-setup.git
git push -u origin main
```

Замените `USERNAME` на свой GitHub-логин. Файл `config.env` исключён через `.gitignore`.
