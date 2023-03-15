#!/usr/bin/python3
from pytube import Playlist
from pytube import YouTube
import time, random
import sys

if len(sys.argv) > 1 and 'https' in sys.argv[1]:
    p = Playlist(sys.argv[1])
else:
    p = Playlist(input("Input Youtube Playlist: "))

def downloader(url):
    try:
        yt = YouTube(url)
        print(yt.title, url)
        stream = yt.streams.get_highest_resolution()
        stream.download(max_retries=3)
    except:
        downloader(url)

for url in p.video_urls:
    downloader(url)
    time.sleep(random.randint(2,10))
