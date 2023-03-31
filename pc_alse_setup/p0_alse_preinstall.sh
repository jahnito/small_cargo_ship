#!/bin/bash
# Проверка соединения
URL="http://10.0.0.1/vipnetclient-gui_s_gost_ru_amd64_4.9.0-6489.deb"
SERVER="10.0.0.1"
ping -c 4 $SERVER > /dev/null
wget -q --spider --timeout=20 http://$SERVER

if [ $? -eq 0 ]; then
    echo "Соединение c сервером прошло успешно!"
else
    echo "Отсутствует соединение с сервером, проверьте настройки и работоспособность сети!"; exit 1
fi
# Загрузка инсталятора
wget $URL
# Установка Vipnet
dpkg -i vipnetclient-gui_s_gost_ru_amd64_4.9.0-6489.deb
# Удаление инсталятора
rm vipnetclient-gui_s_gost_ru_amd64_4.9.0-6489.deb
# Запуск программы для первичной инициализации
astra-mic-control disable
