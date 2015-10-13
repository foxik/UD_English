#!/bin/sh

cat *.conllu | perl merge.pl eng_web_plain/*.txt
