#!/bin/bash
# 
# Установить атрибут исполняемости и запустить
#
# chmod +x P1_ALSE_UPGRADE.ch
#
# Проверка доступности сервера
SERVER="10.0.0.1"
ping -c 4 $SERVER > /dev/null
wget -q --spider --timeout=20 http://$SERVER
if [ $? -eq 0 ]; then
    echo "Соединение c сервером прошло успешно!"
else
    echo "Отсутствует соединение с сервером, проверьте настройки и работоспособность сети!"; exit 1
fi

# Установка репозиториев
cat <<EOL > /etc/apt/sources.list
deb http://$SERVER/astra16/smolensk/ smolensk main contrib non-free
deb http://$SERVER/astra16/smolenskdev/ smolensk main contrib non-free
deb http://$SERVER/astra16/update/ smolensk main contrib non-free
deb http://$SERVER/astra16/updatedev/ smolensk main contrib non-free
deb http://$SERVER/astra16/hot/ smolensk main contrib non-free
EOL

# Установка ключа репозитория
wget -qO - http://$SERVER/astra16/hot/hot.repo.key | sudo apt-key add -
# Обновление пакетной базы
apt update -y
apt dist-upgrade -y

# Перезагрузка системы после обновления
reboot
