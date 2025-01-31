import csv
import glob
import json
import sys


def json_list_to_csv(json_files, csv_file):
    with open(csv_file, 'w', newline='', encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow([
            "doi", "topics", "test_id", "test_name", "N", "test_p_value", "factor", "effectsize_id",
            "effectsize_measure", "effectsize_value", "CI_upper", "CI_lower", "CI_type"
        ])

        for json_file in json_files:
            try:
                parse_file(writer, json_file)
            except KeyError as e:
                print(f"Faild parsing file {json_file}:")
                print(e)


def parse_file(writer, json_file):
    print(f"Parsing {json_file}")
    count = 0
    with open(json_file, 'r', encoding="utf-8") as f:
        data = json.load(f)

    doi = data['doi']
    topics = ';'.join(data['topics'])

    for test_id, test in enumerate(data['tests'], start=1):
        print(f"meine id ist {test_id}")
        if 'effectsizes' or 'effect_size' or 'effect_sizes' in test:  # If there are effect sizes directly in the test
            count += write_effect_lines(writer, doi, topics, test_id, test, test, "")

        if 'factors' in test:  # If the test has factors
            for factor in test['factors']:
                count += write_effect_lines(writer, doi, topics, test_id, test, factor, factor['factor'])
    print(f"Found {count} effects")


def write_effect_lines(writer, doi, topics, test_id, test, effect_list, factor_name):
    count = 0
    if get_effects(effect_list):
        for effectsize_id, effectsize in enumerate(get_effects(effect_list), start=1):
            write_effect(writer, doi, topics, test_id, test, get_p_value(effect_list), effectsize_id, effectsize,
                         factor_name)
            count += 1
    else:
        write_effect(writer, doi, topics, test_id, test, get_p_value(effect_list), "", None, factor_name)
        count += 1
    return count


def get_effects(test):
    if 'effectsizes' in test:
        return test['effectsizes']
    if 'effect_size' in test:
        return [test['effect_size']]
    if 'effect_sizes' in test:
        return test['effect_sizes']


def get_p_value(test):
    return get_value(['p_value', 'p-value'], test)


def write_effect(writer, doi, topics, test_id, test, p_value, effectsize_id, effectsize, factor_name=''):
    if effectsize:
        writer.writerow([
            doi, topics, test_id, test['test_name'], test['N'], p_value,
            factor_name, effectsize_id, get_measure(effectsize),
            effectsize['value'], effectsize['CI']['upper'],
            effectsize['CI']['lower'], get_ci_type(effectsize)
        ])
    else:
        writer.writerow([
            doi, topics, test_id, test['test_name'], test['N'], p_value,
            factor_name, effectsize_id, "", "", "", "", ""
        ])


def get_value(keys, obj):
    for key in keys:
        if key in obj:
            return obj[key]
    raise KeyError


def get_ci_type(effectsize):
    return get_value(['CI_type', 'type'], effectsize['CI'])


def get_measure(effectsize):
    return get_value(['effectsize_measure', 'measure'], effectsize)


if __name__ == "__main__":
    if len(sys.argv) == 3:
        _, directory, csv_file = sys.argv
        paper_paths = glob.glob(directory + "/**/*.json", recursive=True)
        json_list_to_csv(paper_paths, csv_file)
    else:
        script_name = sys.argv[0]
        print(f"Error: This script requires exactly 2 arguments.")
        print(f"Usage: python {script_name} <path_to_json_files> <path_to_csv>")
