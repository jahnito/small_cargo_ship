#!/usr/bin/python3
from pytube import Playlist
from pytube import YouTube
import time, random

l = input("Input Youtube Playlist: ")
p = Playlist(l)

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
