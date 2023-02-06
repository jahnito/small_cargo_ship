#!/usr/bin/env python3
'''
Автоматизированный загрузчик сертификатов Федерального Казначейства
cer, crt - сертификаты
crl - списки отзывов
'''
import re
import urllib.request
from urllib.parse import quote
from pprint import pprint
import hashlib
import subprocess


def downloader(url='http://crl.roskazna.ru/crl/', infofile='ucfk_downloader_info.txt'):
    rgx = r'<a href="(?P<file>.*(?:.cer|.crt|.crl))">(?P<desc>.*)<\/a>'
    files = []
    d_files = []
    with open(infofile, 'w') as f:
        pass
    with urllib.request.urlopen(url) as page:
        html = page.read().decode('utf-8').split('\n')
        for line in html:
            match = re.search(rgx, line)
            if match:
                files.append(match.groups())
    for i in files:
        if 'http' in i[0]:
            print(f'Скачиваю файл {i[0]}')
            try:
                urllib.request.urlretrieve(i[0], transliterate(i[0].split('/')[-1]))
                with open(infofile, 'a') as f:
                    f.write(transliterate(i[0].split('/')[-1]) + ';' + md5file(transliterate(i[0].split('/')[-1])) + '\n')
                d_files.append(transliterate(i[0].split('/')[-1]))
            except (urllib.error.ContentTooShortError) as err:
                print(f'Не удалось скачать файл {i[0]}')
        else:
            print(f'Скачиваю файл {i[0]}')
            try:
                urllib.request.urlretrieve(url + quote(i[0]), transliterate(i[0]))
                with open(infofile, 'a') as f:
                    f.write(transliterate(i[0]) + ';' + md5file(transliterate(i[0])) + '\n')
                d_files.append(transliterate(i[0]))
            except (urllib.error.ContentTooShortError) as err:
                print(f'Не удалось скачать файл {i[0]}')
    return d_files


def transliterate(line: str) -> str:
    '''
    Транслитерация и сокращение имён скачиваемых файлов
    '''
    slovar = {'а':'a','б':'b','в':'v','г':'g','д':'d','е':'e','ё':'yo',
      'ж':'zh','з':'z','и':'i','й':'i','к':'k','л':'l','м':'m','н':'n',
      'о':'o','п':'p','р':'r','с':'s','т':'t','у':'u','ф':'f','х':'h',
      'ц':'c','ч':'ch','ш':'sh','щ':'sch','ъ':'','ы':'y','ь':'','э':'e',
      'ю':'u','я':'ya'}

    extension = line[-4:]
    words = []
    for word in line[:-4].lower().split():
        if len(word) > 3 and word.isalpha():
            word = word[:3]
        for key in slovar:
            word = word.replace(key, slovar[key])
        words.append(word)
    result_line = '_'.join(words) + extension
    return result_line


def md5file(filename) -> str:
    '''
    Получение md5 файла
    '''
    md5 = hashlib.md5()
    with open(filename, 'rb') as f:
        for chunk in iter(lambda: f.read(4096), b''):
            md5.update(chunk)
    return md5.hexdigest()


def packing_to_arch(files: list, arch_name='arch'):
    ff = ' '.join(files)
    proc = subprocess.run('tar -cjf {}.tbz {}'.format(arch_name, ff), shell=True)
    if proc.returncode == 0:
        print('Сертификаты упакованы в архив')
    else:
        print('Чтото пошло не так...')


ucfk_url = 'http://crl.roskazna.ru/crl/'


if __name__ == "__main__":    
    packing_to_arch(downloader())
