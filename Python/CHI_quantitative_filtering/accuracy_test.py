import csv


def compare_csv_rows(file1, file2):
    with open(file1, 'r') as csvfile1, open(file2, 'r') as csvfile2:
        reader1 = csv.DictReader(csvfile1, delimiter=';')
        reader2 = csv.DictReader(csvfile2, delimiter=';')
        counter = 0
        true_counter = 0
        for row1, row2 in zip(reader1, reader2):
            ground_truth = row1['Ground Truth']
            one_true = row2['one_true']

            # Convert values to bool for comparison
            ground_truth_bool = True if ground_truth == 'T' else False
            one_true_bool = True if one_true == 'True' else False

            if ground_truth_bool == one_true_bool:
                print(f"Row {reader1.line_num}: Match")
                true_counter += 1
            else:
                print(f"Row {reader1.line_num}: Mismatch")
            counter += 1
        print("Accuracy:", true_counter / counter)
    return true_counter / counter


# this only works if the papers listed in the sample CSV are exactly the same papers as in the sample_gt and in the same order
# see our files in Data/list_of_gt_CHI_papers
years = [2019, 2020, 2021, 2022, 2023]
total = 0
for year in years:
    print(str(year))
    total += compare_csv_rows(str(year) + '_sample_gt.csv', str(year) + '_sample.csv')
print("Total Accuracy:", total / len(years))

# Accuracy might be biased, as manually verifying the papers relies on
# quickly scanning the text for similar elements as the filters do
