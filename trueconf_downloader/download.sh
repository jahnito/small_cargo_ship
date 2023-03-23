#!/bin/bash
#path="/tmp/svks_download/"
wget --no-check-certificate https://10.180.0.98/downloads/svks-m_astrase1.6_amd64_signed.deb
vers=`dpkg-deb -I svks-m_astrase1.6_amd64_signed.deb | grep Version | cut -d " " -f 3`
old_vers=`cat old_vers.txt`

#mkdir -p $path
#cd $path

if [ "$vers" = "$old_vers" ];
then
    echo "Скачивание не требуется, удаляю временные файлы"
    sleep 2
    rm svks-m_astrase1.6_amd64_signed.deb
else
    echo "Получена новая версия, требуется загрузка на сервер"
    sleep 2
    echo $vers > old_vers.txt
    mv svks-m_astrase1.6_amd64_signed.deb svks-m_$vers.deb
fi
