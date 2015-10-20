#!/bin/sh

cat *.conllu | perl merge_to_anot.pl eng_web_files/*/*.txt
