#!/bin/bash
# Fix SudisWebServer log overload
# Created by Jahn 2023.04.11

echo '''

# Sudis overload logfile fix
if ( $programname == "SudisWebServer" ) then {
   action(type="omfile" file="/dev/null")
}

if ( $programname startswith "Sudis" ) then {
    action(type="omfile" file="/var/log/sudis_shit.log")
}

''' >> /etc/rsyslog.conf

echo 'KARAMBA' > /var/log/daemon.log
echo 'KARAMBA' > /var/log/syslog
rm -rf /var/log/syslog.*

/usr/sbin/rsyslogd -N 1 2>&1 > /dev/null

if [ $? -eq 0 ]; then
    echo "Внесена фича удаления выхлопа SudisWebServer в /dev/null"
else
    echo "Изменения не внесены, возможно не достаточно прав на запись в rsyslog.conf, либо в конфигурации ошибка..."
fi