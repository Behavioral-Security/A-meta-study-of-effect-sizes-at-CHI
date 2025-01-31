"""Module to parse CHI papers
"""
import csv
import io
import re
from copy import copy
from pathlib import Path

from bs4 import BeautifulSoup


class PaperParser:
    """Class to parse CHI papers"""

    def __init__(self, html_path: Path):
        self.html_path = html_path
        with open(html_path, encoding="utf-8") as html_file:
            html_content = html_file.read()
        self.soup = BeautifulSoup(html_content, "html.parser")

    def get_title(self) -> str:
        """Returns the title of a paper"""
        title_tag = self.soup.find("title")
        if title_tag is None:
            raise RuntimeError("Title not found!")
        return title_tag.text.strip()

    def get_abstract(self) -> str:
        """Returns the abstract of a paper"""
        abstract_tag = self.soup.find("div", class_="abstract")
        if abstract_tag is None:
            raise RuntimeError("Abstract not found!")
        return abstract_tag.text.strip()

    def get_section_index(self):
        """Returns the index of a paper"""
        index = []
        pattern = re.compile(r"^sec")
        sections = self.soup.find_all("section", id=pattern)
        for section in sections:
            for header in section.find_all(["h2", "h3"]):
                section_number = header.find("span", class_="section-number")
                section_title = (
                    header.text.replace(section_number.text, "").strip() if section_number else header.text.strip()
                )
                # skip unwanted sections
                unwanted_sections = ["references", "acknowledgments", "acknoweldgements", "footnote", "appendix"]
                if any(section_name in section_title.lower() for section_name in unwanted_sections):
                    continue
                index.append({"index": section_number.text.strip() if section_number else "", "title": section_title})
        return index

    def get_table_index(self):
        """Returns the index of tables"""
        index = []
        for table_div in self.soup.find_all("div", class_="table-responsive"):
            id_value = table_div.get("id", "")
            # skip if the id is not present
            if not id_value or "tab" not in id_value:
                continue
            # remove the "tab"/"tb" from the table id after getting it
            table_index = re.search(r'\d+', id_value).group()
            caption = table_div.find("div", class_="table-caption")
            if caption:
                table_title = (caption.find("span", class_="table-title").
                               text.strip()) if caption.find("span", class_="table-title") else ""
                index.append({"index": table_index, "title": table_title})
        return index

    @staticmethod
    def replace_match(match):
        """Split the matched numbers by comma, strip whitespace, and rejoin"""
        numbers = re.split(r"\s*,\s*", match.group(1))
        return f"[{','.join(numbers)}]"

    def clean_cite(self, text: str) -> str:
        """Function to make citations readable"""
        pattern = re.compile(r"\[\s*(\d+(?:\s*,\s*\d+)*)\s*\]")
        return re.sub(pattern, PaperParser.replace_match, text)

    def get_section_text_by_index(self, index):
        """Returns the section text for a given index"""

        pattern = re.compile(r"^sec")
        sections = self.soup.find_all("section", id=pattern)
        for section in sections:
            section_number = section.find(class_="section-number")
            if section_number and section_number.get_text().strip() == str(index):
                section_copy = copy(section)
                # Remove any tables
                for table_div in section_copy.find_all("div", class_="table-responsive"):
                    table_div.decompose()
                # Remove any figures
                for figure_to_remove in section_copy.find_all("figure"):
                    figure_to_remove.decompose()
                return self.clean_cite(section_copy.get_text())
        raise ValueError(f'No section with index "{index}" available!')

    def get_table_by_index(self, index) -> (str, str):
        """Returns the table as CSV"""

        def table_to_csv_string(table_bs4):
            # Create a StringIO object to hold the CSV data
            output = io.StringIO()
            writer = csv.writer(output)

            # Find the table rows
            rows = table_bs4.find_all('tr')

            for row in rows:
                # Find all the cells in the row
                cells = row.find_all(['th', 'td'])
                # Extract text from each cell
                cell_texts = [cell.get_text(strip=True) for cell in cells]
                # Write the row to the CSV
                writer.writerow(cell_texts)

            # Get the CSV string from the StringIO object
            csv_string = output.getvalue()
            output.close()

            return csv_string

        for table_div in self.soup.find_all("div", class_="table-responsive"):
            id_value = table_div.get("id", "")
            # skip if the id is not present or just an equation
            if not id_value or "tab" not in id_value:
                continue
            # remove the "tab" from the table id after getting it
            table_index = re.search(r'\d+', id_value).group()
            caption = table_div.find("div", class_="table-caption")
            if caption:
                table_title = (caption.find("span", class_="table-title").
                               text.strip()) if caption.find("span", class_="table-title") else ""
            else:
                table_title = ""
            if index == table_index:
                return table_title, table_to_csv_string(table_div)
        raise ValueError(f'No table with index "{index}" available!')

    def get_section_text_by_title(self, title):
        """Returns the section text for a given title"""
        pattern = re.compile(r"^sec")
        sections = self.soup.find_all("section", id=pattern)
        for section in sections:
            headers = section.find_all("header")
            for header in headers:
                title_info = header.find("div", class_="title-info")
                if title_info.get_text().strip().endswith(title):
                    section_copy = copy(section)
                    # Remove any tables
                    for table_div in section_copy.find_all("div", class_="table-responsive"):
                        table_div.decompose()
                    # Remove any figures
                    for figure_to_remove in section_copy.find_all("figure"):
                        figure_to_remove.decompose()
                    return self.clean_cite(section_copy.get_text())
        raise ValueError(f'No section with title "{title}" available!')


def test(path: Path):
    """Test the paperparser"""
    print(f"Testing: {path}")
    # Example usage:
    parser = PaperParser(path)
    print("=" * 80)
    print(parser.get_title())
    print("=" * 80)
    print(parser.get_abstract())
    print("=" * 80)
    indi = (parser.get_section_index())
    print(indi)
    print("=" * 80)
    for index in indi:
        try:
            parser.get_section_text_by_index(index["index"])
        except ValueError:
            parser.get_section_text_by_title(index["title"])
    print("=" * 80)
    table_indi = (parser.get_table_index())
    print(table_indi)
    print("=" * 80)
    for index in table_indi:
        parser.get_table_by_index(index["index"])


if __name__ == "__main__":
    folder = Path("")
    paper = folder / "3580810.html"
    test(paper)
