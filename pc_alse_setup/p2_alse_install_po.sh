#!/bin/bash
# 
# 
#
# chmod +x P2_ALSE_INSTALL_PO.ch
#
# Проверка доступности сервера
SERVER="10.0.0.1"
SERVER_KSC="10.0.0.100"

ping -c 4 $SERVER > /dev/null
wget -q --spider --timeout=20 http://$SERVER
if [ $? -eq 0 ]; then
    echo "Соединение c сервером прошло успешно!"
else
    echo "Отсутствует соединение с сервером, проверьте настройки и работоспособность сети!"; exit 1
fi

# Установка КриптоПро
apt-get install -y cprocsp-compat-debian lsb-cprocsp-base lsb-cprocsp-rdr-64 lsb-cprocsp-kc2-64 lsb-cprocsp-capilite-64 cprocsp-curl-64 lsb-cprocsp-ca-certs cprocsp-rdr-gui-gtk-64 cprocsp-rdr-pcsc-64 cprocsp-rdr-emv-64 cprocsp-rdr-inpaspot-64 cprocsp-rdr-mskey-64 cprocsp-rdr-novacard-64 cprocsp-rdr-rutoken-64 cprocsp-cpopenssl-base cprocsp-cpopenssl-64 cprocsp-cpopenssl-gost-64 cprocsp-stunnel-64 lsb-cprocsp-pkcs11-64
 
# Установка пакетов для обеспечения работы КриптоПро
apt-get install -y lsb-base lsb-release libccid pcscd libpcsclite1 libp11-2 opensc-pkcs11 jq curl bzip2
apt-get install -y pcsc-tools opensc cprocsp-pki-cades cprocsp-pki-plugin ifd-rutokens

# Активация КриптоПро
lic=`wget -q -O - http://$SERVER/CryptoPro/lic | cat`
/opt/cprocsp/sbin/amd64/cpconfig -license -set $lic

# Установка корневых и доверенных сертификатов УЦ
apt-get install -y bzip2
wget http://$SERVER/bad_soft/UC/latest.tbz
tar xf latest.tbz

# Очищаем хранилища сертификатов
/opt/cprocsp/bin/amd64/certmgr -delete -store mRoot -all > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "Очищено хранилище корневых сертификатов mRoot"
else
    echo "Хранилище сертификатов mRoot не имеет сертификатов"
fi

/opt/cprocsp/bin/amd64/certmgr -delete -store mCA -all > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "Очищено хранилище корневых сертификатов mCA"
else
    echo "Хранилище сертификатов mCA не имеет сертификатов"
fi

crtsRoot=( $( ls | grep -E "^kor.*.?(crt|cer)$") )
crtsCA=( $(ls | grep -E "^(pod|ucfk).*.?(crt|cer)$") )
crls=( $( ls *.crl ) )

# Установка корневых сертификатов
for i in ${crtsRoot[@]}
do
    /opt/cprocsp/bin/amd64/certmgr -inst -cert -file $i -store mRoot > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "Установлен корневой сертификат $i в mRoot"
        rm $i -f
    else
        echo "Что-то пошло не так на файле $i"
        echo "Файл $i не удалён для ручной обработки..."
    fi
done

# Установка промежуточных сертификатов
for i in ${crtsCA[@]}
do
    /opt/cprocsp/bin/amd64/certmgr -inst -cert -file $i -store mCA > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "Установлен промежуточный сертификат $i в mCA"
        rm $i -f
    else
        echo "Что-то пошло не так на файле $i"
        echo "Файл $i не удалён для ручной обработки..."
    fi
done

# Установка списков отзыва
for i in ${crls[@]}
do
    /opt/cprocsp/bin/amd64/certmgr -inst -crl -file $i -store mCA > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "Установлен список отзыва $i в mCA"
        rm $i -f
    else
        echo "Что-то пошло не так на файле $i"
        echo "Файл $i не удалён для ручной обработки..."
    fi
done

# Установка СУДИС
apt-get install -y fly_dmgreet_sudis pam_sudis sudis_rtmonitor sudis_webserver
pam-auth-update --force
 
# Установка антивируса
apt-get install kesl-astra klnagent64-astra


ping -c 4 $SERVER_KSC > /dev/null
 
cat <<EOL > ./kesl_install.ini
EULA_AGREED=Yes
PRIVACY_POLICY_AGREED=Yes
USE_KSN=No
SERVICE_LOCALE=ru_RU.UTF-8
UPDATER_SOURCE=SCServer
#PROXY_SERVER=
UPDATE_EXECUTE=Yes
KERNEL_SRCS_INSTALL=No
USE_GUI=Yes
USE_FANOTIFY=No
EOL
 
cat <<EOL > ./autoanswers.conf
KLNAGENT_SERVER=$SERVER_KSC
KLNAGENT_PORT=14000
KLNAGENT_SSLPORT=13000
KLNAGENT_USESSL=Y
KLNAGENT_GW_MODE=1
KLNAGENT_GW_ADDRESS=
EOL
 
# Инициализация агента администрирования
/opt/kaspersky/klnagent64/lib/bin/setup/postinstall.pl --auto
# Инициализация антивирусной программы
/opt/kaspersky/kesl/bin/kesl-setup.pl --autoinstall=kesl_install.ini 2>&1 >/dev/null

# Перезагрузка
reboot