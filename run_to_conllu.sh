#!/bin/sh

cat *.conllu | perl merge_to_conllu.pl eng_web_plain/*.txt
