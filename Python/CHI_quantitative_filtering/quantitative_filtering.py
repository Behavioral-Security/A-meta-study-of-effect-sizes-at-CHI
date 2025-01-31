import csv
import random
import re
import zipfile

from bs4 import BeautifulSoup

# Set the random seed to keep same sample after execution - was chosen at random from 1 - 10_000_000
random.seed(7_038_360)
# amount of papers we want to sample, choose -1 to select all
sample_size = -1


def choose_sample(archive, paper_sample_size):
    # Randomly choose paper from html files
    html_files = [file.filename for file in archive.filelist if file.filename.endswith(".html")]
    if paper_sample_size == -1:
        paper_sample_size = len(html_files)
    selected_htmls = random.sample(html_files, paper_sample_size)
    return selected_htmls


def write_csv(filename, headers, data):
    with open(filename, 'w', newline='') as csvfile:
        writer = csv.writer(csvfile, delimiter=";")
        writer.writerow(headers)
        for row in data:
            writer.writerow(row)


def get_html_text_noref(html):
    soup = BeautifulSoup(html, 'html.parser')

    # Find all elements with class 'bibUl' (References) and remove them
    for element in soup.find_all(class_='bibUl'):
        element.decompose()
    text_content = soup.get_text()
    return text_content


def quantitative_filter(html_string, filter_type="p_filter", detail=False):
    match filter_type:
        case "p_filter":
            # find any occurrence of p reporting
            pattern = r"[\(\s]\s*p(\s+[a-zA-Z-]{0,12})?\s*[=<>]"
            match = re.search(pattern, html_string)
        case "p_val_filter":
            # find any occurrence of p-val wording
            pattern = r"\sp\s*-?\s*val"
            match = re.search(pattern, html_string)
        case "bayesian_filter":
            # find any occurrence of bayes factor wording
            pattern = r'bayes\s*factor'
            match = re.search(pattern, html_string, re.IGNORECASE)
        case "ci_filter":
            # find any occurrence of confidence interval wording
            pattern = r"confidence\s*interval"
            match = re.search(pattern, html_string, re.IGNORECASE)
        case _:
            print("filter not found")
            return
    if detail:
        return match
    return bool(match)


def quantitative_analysis(zipfile_name, folder):
    # headers defined by the filters
    headers = ['Paper', "one_true", 'p_val', "p - val_str", "CI", "bayes"]
    path = folder + "/" + str(zipfile_name)
    archive = zipfile.ZipFile(path, 'r')
    n = (choose_sample(archive, sample_size))
    print(zipfile_name)
    filtered_paper_list = []
    percentage = 0
    for paper in n:
        html = archive.read(paper)
        text_content = get_html_text_noref(html)
        ci = quantitative_filter(text_content, "ci_filter")
        p = quantitative_filter(text_content, "p_filter")
        p_val = quantitative_filter(text_content, "p_val_filter")
        bayes = quantitative_filter(text_content, "bayesian_filter")
        one_true = ci or p or p_val or bayes
        percentage += int(one_true)
        filtered_paper_list.append((paper, one_true, p, p_val, ci, bayes))
    print("quant percentage: ", percentage / len(n))

    write_csv(str(zipfile_name[:-4]) + "_sample.csv", headers, filtered_paper_list)


# Path to the directory containing the zip archives with the html papers
html_zip_folder = r"CHI_HTML_download\html_paper_zip"
# run the quantitative analysis on all years
for zip_file in ["2019.zip", "2020.zip", "2021.zip", "2022.zip", "2023.zip"]:
    quantitative_analysis(zip_file, html_zip_folder)
