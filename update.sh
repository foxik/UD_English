#!/bin/sh

perl -pe '
  chomp;
  my @parts = split /\t/;
  if (@parts) {
    $parts[1] =~ s/-LRB-/(/g && $parts[2] =~ s/-lrb-/(/g;
    $parts[1] =~ s/-RRB-/)/g && $parts[2] =~ s/-rrb-/)/g;
    $_ = join("\t", @parts);
  }
  $_ .= "\n";
' -i *.conllu
