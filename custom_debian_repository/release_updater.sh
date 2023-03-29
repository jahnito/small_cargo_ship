#!/bin/bash
#####################################################################################
# Script updates lists after adding files, signs own Debian repository with own key #
#####################################################################################

RELEASE="smolensk"
REPO_DIR="/media/vol2/repo_astra/hot/"
PACKAGES=("contrib" "main" "non-free")
OWNERKEY="jahnito@gmail.com"

cd $REPO_DIR

for package in ${PACKAGES[@]}
do
    echo "Обновляю данные $package ..."
    dpkg-scanpackages pool/$package /dev/null > dists/stable/$package/binary-amd64/Packages
    gzip -9c <dists/stable/$package/binary-amd64/Packages > dists/stable/$package/binary-amd64/Packages.gz
    bzip2 -9c <dists/stable/$package/binary-amd64/Packages > dists/stable/$package/binary-amd64/Packages.bz2
    cat <<EOL > dists/stable/$package/binary-amd64/Release
Origin: Debian
Suite: stable
Codename: $RELEASE
Version: 1.6
Component: $package
Architecture: amd64
EOL
done

cat <<EOL > dists/stable/Release
Origin: Debian
Suite: stable
Codename: $RELEASE
Version: 1.6
Component: ${PACKAGES[@]}
Architecture: amd64
EOL

echo "Генерирую файл Release ..."

cd dists/stable
apt-ftparchive release . >> Release

echo "Подписываю списки GPG ключём ..."
cd $REPO_DIR

gpg -abs --yes -o dists/smolensk/Release.gpg dists/smolensk/Release
gpg --default-key $OWNERKEY --yes --clearsign -o dists/stable/InRelease dists/stable/Release
