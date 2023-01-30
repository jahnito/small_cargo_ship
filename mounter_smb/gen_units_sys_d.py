#!/usr/bin/env python3
import os
import subprocess
import getpass


def generate_units(smb_path: str, username: str, password: str, sudo_pass, timeout=3600):
    '''
    Функция генерирует два файла юнита для монтирования SMB ресурсов, требуются права SUDO или ROOT

    smb_path: полный путь в формате, пример: //10.1.1.5/FTP
    username и password: имя пользователя и пароль SMB сервера
    '''
    mount_dir = smb_path.strip('/').split('/')[-1]
    home_folder = os.environ.get('HOME')
    home_dir = home_folder + '/' + mount_dir
    f_name = '-'.join(home_dir.strip('/').split('/'))
    print(home_dir, f_name + '.mount')
    with open(f_name + '.mount', 'w') as mount:
        mount.write(tpl_mount.format(smb_path, home_dir, username, password))
    with open(f_name + '.automount', 'w') as automount:
        automount.write(tpl_automount.format(home_dir, timeout))
    subprocess.run('echo {} | sudo -S mv {} /etc/systemd/system/ && echo {} | sudo -S mv {} /etc/systemd/system/'.format(sudo_pass, f_name + '.mount', sudo_pass, f_name + '.automount'), shell=True)
    com1 = subprocess.run('echo {} | sudo -S systemctl enable {}'.format(sudo_pass, f_name + '.automount'), stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    com2 = subprocess.run('echo {} | sudo -S systemctl start {}'.format(sudo_pass, f_name + '.automount'), stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    if com1.returncode == 0 and com2.returncode == 0:
        print('Юнит монтирования удаленного каталога создан и доступен в папке')
    else:
        print('При создании юнита произошла ошибка, возможно недостаточно прав')


tpl_mount = '''[Unit]
  Description=cifs mount script
  Requires=network-online.target
  After=network-online.service

[Mount]
  What={}
  Where={}
  Options=username={},password={},rw,uid=1000,gid=1000,vers=1.0
  Type=cifs

[Install]
  WantedBy=multi-user.target'''


tpl_automount = '''[Unit]
  Description=cifs mount script
  Requires=network-online.target
  After=network-online.service

[Automount]
  Where={}
  TimeoutIdleSec={}

[Install]
  WantedBy=multi-user.target'''


if __name__ == '__main__':
    smb_path = input('Enter smb path example: //10.1.1.5/FTP:\n')
    username = input('Enter smb-server Username:\n')
    password =  getpass.getpass('Enter smb-server Password:\n')
    sudo_pass = getpass.getpass('Enter SUDO Password:\n')
    generate_units(smb_path, username, password, sudo_pass)
