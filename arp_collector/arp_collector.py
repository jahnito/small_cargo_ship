#!/usr/bin/env python3
'''
Сборщик - анализатор arp таблиц


https://maclookup.app/downloads/csv-database/get-db?t=23-01-08&h=fb3f0989cd083830f70001b4dc18df0f46b0097d
https://oidref.com/1.3.6.1.2.1.4.20
'''
# import os
import subprocess
# import datetime
# import time


def snmpwalk_check() -> bool:
    '''
    Функция проверки установленного пакета snmp
    необходимо использовать перед вызовом функций snmp
    '''
    if subprocess.call(['which', 'snmpwalk'], stdout=subprocess.PIPE, stderr=subprocess.PIPE) == 1:
        print('Не установлен snmpwalk\nДля установки наберите команду: sudo apt-get install snmp snmp-mibs-downloader')
        return False
    else:
        return True


def icmp_reacheble(address):
    '''
    Функция проверки доступности удаленного узла по icmp
    '''
    ping = subprocess.run(f'ping {address} -c 2', shell=True, stdout=subprocess.PIPE)
    if ping.returncode == 0:
        return True
    return False


def snmp_reacheble(community, address):
    '''
    Функция проверки доступности службы snmp удаленного узла
    '''
    mib = '1.3.6.1.2.1.1.5.0'
    name = subprocess.run(f'snmpwalk -Cc -v2c -c {community} {address} {mib}', stdout=subprocess.PIPE, shell=True)
    if name.stdout:
        return True
    else:
        return False


def snmp_request(community: str, address: str, snmp_mib: str) -> str:
    '''
    Выполнение запроса snmp по протоколу v2
    принимает аргументы: community, address (ip), mib
    возвращает данные в виде текста или списка тектовых данных
    '''
    if not snmpwalk_check():
        return None
    try:
        raw_data = subprocess.run('snmpwalk -Cc -v2c -c {} {} {}'.format(community, address, snmp_mib),
                                  shell=True,
                                  stdout=subprocess.PIPE,
                                  stderr=subprocess.PIPE,
                                  encoding='utf-8')
        return raw_data.stdout
    except ValueError:
        return None


def snmp_arp_table(community: str, address: str) -> dict:
    '''
    Функция возращает словарь ip:mac из arp таблицы маршрутизатора
    '''
    if not icmp_reacheble(address):
        return None
    snmp_mib='1.3.6.1.2.1.4.22.1.2'
    result_arp_table = {}
    for line in snmp_request(community, address, snmp_mib).split('\n'):
        if line.strip():
            raw_ip, raw_mac = map(str.strip, line.split('='))
            if raw_mac.startswith('Hex-STRING:'):
                mac = '{}:{}:{}:{}:{}:{}'.format(*raw_mac.split()[1:])
            elif raw_mac.startswith('STRING:'):
                nubles = []
                for letter in raw_mac.split()[-1].strip('"'):
                    nubles.append(letter.encode('utf-8').hex().upper())
                mac = ':'.join(nubles)
            ip = '.'.join(raw_ip.split('.')[-4:])
        result_arp_table[ip] = mac
    return result_arp_table


snmp_v2_mibs = {'name': '1.3.6.1.2.1.1.5.0',
                'uptime': '1.3.6.1.2.1.1.3.0',
                'hardware': '1.3.6.1.2.1.1.1.0',
                'mac_hex': '1.3.6.1.2.1.4.22.1.2',
                }


community = 'public'


if __name__ == '__main__':
    ip = '192.168.3.254'
    print(snmp_reacheble(community, ip))
    # print(snmp_arp_table('public', '192.168.3.254'))
    # print(snmp_request('public', '192.168.3.254', '1.3.6.1.2.1.4.22.1.2').split('\n'))
