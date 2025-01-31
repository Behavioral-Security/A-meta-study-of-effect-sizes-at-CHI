import pandas as pd
import os
import sys
import re
from bs4 import BeautifulSoup


def generate_measure_mapping():
    # For each entry of effectsize_measure_unified in the effectsizes_measures3.csv file, generate a set of values from
    # the effectsizes_measure column whose effectsize_measure_unified is equal to the entry). Add all these sets to a
    # dictionary with the effectsize_measure_unified as the key. The dictionary will be used to map the
    # effectsize_measure_unified to the possible values of the effectsize_measure column.

    # Load the effectsizes_measures3.csv file into a DataFrame
    df = pd.read_csv("effectsizes_measures3.csv")

    # Create an empty dictionary to store the mappings
    measure_mapping = {}

    # Iterate over the rows of the DataFrame
    for index, row in df.iterrows():
        # Get the unified measure and the measure values
        unified_measure = row["effectsize_measure_unified"]
        measure_values = row["effectsize_measure"]

        # If the unified measure is not already in the dictionary, add it with an empty set as the value
        if unified_measure not in measure_mapping:
            measure_mapping[unified_measure] = set()

        # Add the measure values to the set of values for the unified measure
        measure_mapping[unified_measure].add(measure_values.lower())

    # # print the mapping, for each key value in a new line
    print("---MAPPING OF MEASURES---")
    for key, value in measure_mapping.items():
        print(f"{key}: {value}")
    print("---END OF MAPPING OF MEASURES---")

    # Return the mapping
    return measure_mapping


def duplicate_numbers(input_string):
    # Search for a decimal number in the input string that is not preceded by another digit (scientific dot notation)
    # The pattern matches an optional leading '0' followed by a decimal point and digits (e.g., .123 or 0.123)
    decimal_match = re.search(r'(?<!\d)(0?\.\d+)', input_string)

    if decimal_match:
        # Extract the group containing the decimal point
        decimal_number = decimal_match.group(1)

        # Replace the decimal number in the original string
        with_leading_zero = input_string.replace(decimal_number, '0' + decimal_number.lstrip('0'))
        with_leading_point = input_string.replace(decimal_number, decimal_number.lstrip('0'))

        # Return both versions of the string
        return [with_leading_zero, with_leading_point]

    # If no decimal number is found, return the input string unchanged in a list
    return [input_string]


def check_value(html_content, value, measure_mapping, html_filename):
    # This method checks for the presence of a value in the HTML content. Multiple checks are involved sequentially.

    # Check if the value is in a set of predefined values ("UNKNOWN", "NA", "") or if it's present in the HTML content
    if str(value) in {"UNKNOWN", "NA", ""} or str(value) in html_content:
        return True

    # Reminder: The measure_mapping dictionary is a dictionary whose dictionary values are sets of strings. These
    # strings can be mapped to the unified measure (keys of the dictionary).
    # For each key, value pair of the dictionary, check if the local variable value is one of the dictionary values (which are sets of strings). If it is, check if any of the corresponding key's values are in the HTML content. If they are, return True.
    for unified_measure, measure_variants in measure_mapping.items():
        if str(value).lower() in measure_variants:
            # Check if the any of the unified_measure's values are in the HTML content
            for measure_variant in measure_variants:
                if measure_variant in html_content.lower():
                    # print(f"Found {measure_variant} of mapping class {unified_measure} in HTML file {html_filename}")
                    return True

    try:
        # Try to convert the value to an integer and introduce commas
        int_value = int(value)

        # Check for comma-formatted number
        comma_value = f"{int_value:,}"
        if comma_value in html_content:
            return True
    except ValueError:
        # If conversion fails, it's not an integer, so skip this part
        pass
    try:
        # convert to float and delete leading zeros before the decimal point
        float_value = float(value)
        if 1 > float_value > -1 and float_value != 0:
            formatted_value = f"{float_value}".lstrip("0")  # Maintain all digits after the point
            if formatted_value in html_content:
                return True
    except ValueError:
        pass

    # Define a regular expression pattern to match numbers with possible operators and symbols
    # This matches strings like "=123", ">1,000", "<0.5", "123.45%", etc.
    pattern = re.compile(r"\S*\s*[=+\-<>]\s*\d{0,3}(?:[,]\d{3})*(?:[.]\d+)?\s*[²%]?")

    value = str(value)

    # Check if the value matches the defined pattern
    if pattern.match(value):

        # Generate possible variations of the decimal number (leading zero or leading point)
        str_variations = duplicate_numbers(value)

        # Remove white spaces from the variations
        str_variations = map(lambda x: x.replace(" ", ""), str_variations)

        # Remove white spaces from HTML content
        html_content = html_content.replace(" ", "")

        # Check if any of the variations is present in the HTML content
        for value in str_variations:
            if value in html_content:
                return True

    # If the value is not found in the HTML content for none of the above checks, return False
    return False


def load_html(html_filename):
    if os.path.exists(html_filename):
        # HTML-Datei laden
        with open(html_filename, "r", encoding="utf-8") as file:
            html_content = file.read()

        # Optional: HTML-Inhalt mit BeautifulSoup parsen (nützlich, um das DOM zu navigieren)
            soup = BeautifulSoup(html_content, "html.parser")
            html_text = soup.get_text()  # Rohtext aus dem HTML extrahieren
            return html_text
    else:
        raise FileNotFoundError(f"File {html_filename} does not exist")


def analyze_csv(input_csv, output_csv, paper_dir, mapping_dict):
    # Laden der CSV-Datei in ein DataFrame
    df = pd.read_csv(input_csv)

    # Liste der zu überprüfenden Felder
    fields_to_check = ["N", "test_p_value", "effectsize_measure", "effectsize_value",
                       "CI_upper", "CI_lower", "CI_type"]#, "test_name"]

    # Für jedes zu überprüfende Feld eine neue Spalte erstellen, um festzuhalten, ob der Wert gefunden wurde
    for field in fields_to_check:
        df[f"{field}_found"] = False

    try:
        paper_year = df.iloc[0]["year"]
    except:
        paper_year = input_csv.split("/")[-1].split(".")[0]

    # Zähler für die Statistiken am Ende der Ausführung
    effect_n, effect_h, fields_total, fields_invalid, files_missing = 0, 0, 0, 0, 0
    file_loaded = False
    loaded_file = "None"
    html_text = ""
    # Durch jede Zeile im DataFrame iterieren
    for index, row in df.iterrows():
        effect_n += 1
        doi = row["doi"]
        # use os-module's paths to create an OS-independant path to the HTML document
        html_filename = os.path.join(paper_dir, paper_year, f"{doi_to_filename(doi)}.html")

        if html_filename != loaded_file:
            loaded_file = html_filename
            file_loaded = True
            try:
                html_text = load_html(html_filename)
            except FileNotFoundError as e:
                files_missing += 1
                file_loaded = False

        if not file_loaded:
            continue

        # Überprüfung der Werte in jedem Feld
        row_good = True
        for field in fields_to_check:
            value = row[field]
            fields_total += 1
            if check_value(html_text, value, mapping_dict, html_filename):
                df.at[index, f"{field}_found"] = True
            else:
                print(f"Kaputt {os.path.join(html_filename, field)}: {value}")
                row_good = False
                fields_invalid += 1
        if not row_good:
            effect_h += 1


    # Speichern der Ergebnisse in einer neuen CSV-Datei
    df.to_csv(output_csv, index=False)
    print(f"Analyse abgeschlossen. Ergebnisse wurden in {output_csv} gespeichert.")
    print(f"Effects gesamt {effect_n}")
    print(f"Effects kaputt {effect_h}")
    print(f"Fields gesamt {fields_total}")
    print(f"Fields kaputt {fields_invalid}")
    if files_missing:
        print(f"DANGER: {files_missing} files missing")


def doi_to_filename(doi: str) -> str:
    # DOI in seine Bestandteile aufspalten und den dritten numerischen Teil nach dem zweiten '.' zurückgeben
    return doi.split('.')[2]


if __name__ == "__main__":
    # Überprüfen, ob die richtigen Parameter übergeben wurden
    if len(sys.argv) != 4:
        print("Verwendung: python script.py <input_csv> <output_csv> <paper_dir>")
    else:
        mapping_dict = generate_measure_mapping()

        input_csv = sys.argv[1]
        output_csv = sys.argv[2]
        paper_dir = sys.argv[3]
        analyze_csv(input_csv, output_csv, paper_dir, mapping_dict)
