import csv

import bibtexparser
import requests


# file for processing the .bib file from the chi/database website into a csv with sessions and keywords

def get_session_dict(year):
    print("getting session id for " + str(year))
    urls = {2021: "https://dl.acm.org/doi/proceedings/10.1145/3411764",
            2022: "https://dl.acm.org/doi/proceedings/10.1145/3491102",
            2023: "https://dl.acm.org/doi/proceedings/10.1145/3544548",
            2024: "https://dl.acm.org/doi/proceedings/10.1145/3613904"}
    # Send GET request
    response = requests.get(urls[year])
    session_dict = {}
    if response.status_code == 200:
        content = str(response.content, encoding="UTF-8")
        base_index = 0
        while content[base_index:].find("SESSION") >= 0:
            sessionindex_start = content[base_index:].find("SESSION") + base_index
            sessionindex_stop = content[sessionindex_start:].find("<") + sessionindex_start
            valueindex_start = content[base_index:sessionindex_start].rfind('value="') + 7 + base_index
            valueindex_stop = content[valueindex_start:].find('"') + valueindex_start
            base_index = sessionindex_stop
            Sessionname = (content[sessionindex_start:sessionindex_stop])
            doilist = (content[valueindex_start:valueindex_stop]).split(",")
            for doi in doilist:
                session_dict.update({doi: Sessionname})
    else:
        print(response.status_code)
    return session_dict


def create_csv(filename, year):
    # csv format: title, link, session, keywords
    with open(filename, "r", encoding="utf-8") as bibtex_file:
        bib_database = bibtexparser.parse_string(bibtex_file.read())
        # clear file and add categories
        with open(filename[:-3] + "csv", "w+", newline='', encoding="utf-8") as csvfile:
            # Sessions only exist after 2020
            if year > 2020:
                header = ['Title', 'Link', "Session", 'Keywords']
            else:
                header = ['Title', 'Link', 'Keywords']
            writer = csv.DictWriter(csvfile, fieldnames=header, delimiter=';')
            writer.writeheader()

        # for each paper in the bib file
        with open(filename[:-3] + "csv", "a+", newline='', encoding="utf-8") as csvfile:
            if year > 2020:
                session_dict = get_session_dict(year)
            for item in bib_database.entries:
                try:
                    keywords = item.fields_dict["keywords"].value
                except KeyError:
                    keywords = None
                link = "https://dl.acm.org/doi/fullHtml/" + item.fields_dict["doi"].value
                if year > 2020:
                    session = session_dict[item.fields_dict["doi"].value]
                    paper_info = [item.get("title").value,
                                  link,
                                  session,
                                  keywords]
                else:
                    paper_info = [item.get("title").value,
                                  link,
                                  keywords]
                csvwriter = csv.writer(csvfile, delimiter=';')
                csvwriter.writerow(paper_info)


# dictionary of the files and their associated year
bibfile_dict = {
    '../../Data/Bibliography-Files/2019.bib': 2019,
    '../../Data/Bibliography-Files/2020.bib': 2020,
    '../../Data/Bibliography-Files/2021.bib': 2021,
    '../../Data/Bibliography-Files/2022.bib': 2022,
    '../../Data/Bibliography-Files/2023.bib': 2023,
}
for filename, year in bibfile_dict.items():
    create_csv(filename, year)
