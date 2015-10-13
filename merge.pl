#!/usr/bin/perl
use warnings;
use strict;
use utf8;
use open qw(:std :utf8);

# Read input CoNLL-U
my @conllu;

my %sentences;
my ($sentence, $sentence_start) = ("", 0);
while (<STDIN>) {
  chomp;
  my @parts = split /\t/;
  if (/^$/) {
    if (length $sentence) {
      my $tokens = join " ", map {$_->[1]} @conllu[$sentence_start..$#conllu];
      warn "Multiple occurrences of sentence '$sentence' with different tokens $tokens and $sentences{$sentence}->{tokens}" if exists $sentences{$sentence} && $tokens ne $sentences{$sentence}->{tokens};
      $sentences{$sentence} = {ranges=>[], tokens=>$tokens} if not exists $sentences{$sentence};
      push @{$sentences{$sentence}->{ranges}}, {start=>$sentence_start, end=>$#conllu};
    }
    $sentence = "";
    $sentence_start = scalar(@conllu) + 1;
  } else {
    $sentence .= $parts[1];
  }
  push @conllu, [@parts];
}

# Read input plain text


# Write output CoNLL-U
