import sys
import csv
from argparse import ArgumentParser
import numpy as np
from tqdm import tqdm


def levenshtein(source, target):
    if len(source) < len(target):
        return levenshtein(target, source)

    # So now we have len(source) >= len(target).
    if len(target) == 0:
        return len(source)

    # We call tuple() to force strings to be used as sequences
    # ('c', 'a', 't', 's') - numpy uses them as values by default.
    source = np.array(tuple(source))
    target = np.array(tuple(target))

    # We use a dynamic programming algorithm, but with the
    # added optimization that we only need the last two rows
    # of the matrix.
    previous_row = np.arange(target.size + 1)
    for s in source:
        # Insertion (target grows longer than source):
        current_row = previous_row + 1

        # Substitution or matching:
        # Target and source items are aligned, and either
        # are different (cost of 1), or are the same (cost of 0).
        current_row[1:] = np.minimum(
                current_row[1:],
                np.add(previous_row[:-1], target != s))

        # Deletion (target grows shorter than source):
        current_row[1:] = np.minimum(
                current_row[1:],
                current_row[0:-1] + 1)

        previous_row = current_row

    return previous_row[-1]

def main():
    argparser = ArgumentParser(description="Compare the text of speeches in the storting dataset.")
    argparser.add_argument('--gold', help="path to the gold dataset", required=True)
    argparser.add_argument('--ocr', help="path to the dataset generated with ocr")
    args = argparser.parse_args()

    gold = csv.DictReader(open(args.gold))
    ocr = csv.DictReader(open(args.ocr))

    best = sys.maxint
    best_i = 0
    worst = 0
    worst_i = 0

    scores = []

    for i, go in enumerate(tqdm(zip(gold, ocr))):
        g, o = go
        ld = levenshtein(g['text'].split(), o['text'].split())
        scores.append(ld)
        if ld <= best:
            best = ld
            best_i = i
        if ld >= worst:
            worst = ld
            worst_i = i

    print "Average ld:", sum(scores) / float(len(scores))
    print "Best:", best_i
    print "Worst:", worst_i



if __name__ == '__main__':
    main()
