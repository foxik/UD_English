#!/bin/sh

for conllu in *.conllu; do
  perl merge.pl eng_web_plain/*.txt <$conllu >$conllu.merged
done
