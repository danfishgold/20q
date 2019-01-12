from bs4 import BeautifulSoup
import requests
import re

base_url = 'https://www.haaretz.co.il'
all_url = '/magazine/20questions'
all_req = requests.get(base_url + all_url)
all_soup = BeautifulSoup(all_req.text)
today_element = all_soup.find_all('article', {'class': 'hero'})[0]
today_url = today_element.a.attrs['href']
today_id = re.search('/magazine/20questions/([\.\d]+)', today_url).group(1)
today_date = today_element.time.attrs['datetime']

today_req = requests.get(base_url + today_url)
today_soup = BeautifulSoup(today_req.text)
title = today_soup.article.header.h1.text
try:
    today_image = today_soup.article.figure.img.attrs['src']
except NoneType:
    today_image = None


yoanas_xls_url = '/st/inter/DB/heb/20q/20q.xlsx'
actual_data_url = '/st/c/work/guy/2018/21q/data.js'

actual_data_req = requests.get(base_url + actual_data_url)
actual_data_text = actual_data_req.text
    .replace('\n', '')
    .replace('\r', '')
    .replace("\\'", "'")
    .strip('var newData = ')

questions_and_answers_dict = json.loads(actual_data_text)[today_id]
questions_and_answers = []
    