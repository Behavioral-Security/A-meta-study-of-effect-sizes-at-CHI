import concurrent.futures
import csv
import os
import re
import sys
import time
from os.path import isfile, join
from urllib.parse import urljoin

import requests
from bs4 import BeautifulSoup


def savePage(url, year, pagepath='page'):
    pagepath = year + "/" + url[-7:]

    def savenRename(soup, pagefolder, url, tag, inner):
        if not os.path.exists(pagefolder):  # create only once
            os.mkdir(pagefolder)
        for res in soup.findAll(tag):
            if res.has_attr(inner):  # check inner tag (file object) MUST exists
                try:
                    filename, ext = os.path.splitext(os.path.basename(res[inner]))  # get name and extension
                    ext = re.sub(r'\?.*', '', ext)
                    filename = re.sub('\W+', '', filename) + ext  # clean special chars from name
                    fileurl = urljoin(url, res.get(inner))
                    filepath = os.path.join(pagefolder, filename)
                    # rename html ref so can move html and folder of files anywhere
                    res[inner] = os.path.join(os.path.basename(pagefolder), filename)
                    if not os.path.isfile(filepath):  # was not downloaded
                        os.makedirs(os.path.dirname(filepath), exist_ok=True)
                        with open(filepath, 'wb') as file:
                            filebin = download_loop(fileurl)
                            file.write(filebin.content)
                except Exception as exc:
                    print(exc, file=sys.stderr)

    response = download_loop(url)
    soup = BeautifulSoup(response.text, "html.parser")
    path, _ = os.path.splitext(pagepath)
    pagefolder = path + '_files'  # page contents folder
    tags_inner = {'img': 'src', 'link': 'href', 'script': 'src'}  # tag&inner tags to grab
    for tag, inner in tags_inner.items():  # saves resource files and rename refs
        savenRename(soup, pagefolder, url, tag, inner)
    with open(path + '.html', 'wb') as file:  # saves modified html doc
        file.write(soup.prettify('utf-8'))


def download_loop(url):
    headers = {
        "User-Agent": "Chrome/121.0.6167.139",
    }
    print("downloading " + url)
    download_unsuccessful = True
    session = requests.Session()
    while download_unsuccessful:
        # Send GET request
        response = session.get(url, headers=headers)
        # Save the HTML
        if response.status_code == 200:
            return response
        else:
            print(response.status_code)
            print("waiting 30 mins")
            time.sleep(1800)


def parallell_download(urllist, year):
    # List of parameters
    parameters_list = [(url, year) for url in urllist]
    # Maximum number of concurrent tasks (adjust as needed)
    max_workers = 1

    # Create a ThreadPoolExecutor
    with concurrent.futures.ThreadPoolExecutor(max_workers=max_workers) as executor:
        # Submit tasks to the executor for each parameter in the list
        futures = [executor.submit(savePage, url, year) for url, year in parameters_list]

        # Wait for all tasks to complete
        for future in concurrent.futures.as_completed(futures):
            # Retrieve any exceptions that might have occurred in the function
            exc = future.exception()
            if exc:
                print(f'Function raised an exception: {exc}')


# csv: title, link, keywords
def start_download(csvfile, year_int):
    urllist = []
    year = str(year_int)
    with open(csvfile, 'r', encoding="UTF-8") as f:
        reader = csv.reader(f, delimiter=";")
        next(reader, None)
        if not os.path.exists(year):  # year folder
            os.mkdir(year)
        # checks if files are present, if so we can skip downloading them again
        present_files = [f for f in os.listdir(year) if isfile(join(year, f))]
        for row in reader:
            if not row[1][-7:] + ".html" in present_files:
                urllist.append(row[1])

    parallell_download(urllist, year)
    print("finished!")


bibfile_dict = {
    '../../Data/Bibliography-Files/2019.csv': 2019,
    '../../Data/Bibliography-Files/2020.csv': 2020,
    '../../Data/Bibliography-Files/2021.csv': 2021,
    '../../Data/Bibliography-Files/2022.csv': 2022,
    '../../Data/Bibliography-Files/2023.csv': 2023,
}
for filename, year_int in bibfile_dict.items():
    start_download(filename, year_int)
