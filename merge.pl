#!/usr/bin/perl
use warnings;
use strict;
use utf8;
use open qw(:std :utf8);

# Read input CoNLL-U
my @conllu;

my %sentences;

my ($sentence, $sentence_start) = ("", 0);
while (defined ($_ = <STDIN>) || length $sentence) {
  chomp;

  my @parts = split /\t/;

  # Deal with -[LR]RB- in Form and Lemma columns.
  @parts && $parts[1] =~ s/-LRB-/(/g && $parts[2] =~ s/-lrb-/(/g;
  @parts && $parts[1] =~ s/-RRB-/)/g && $parts[2] =~ s/-rrb-/)/g;

  if (!@parts) {
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

# Generate all sentence prefixes
my %sentence_prefixes;
foreach my $sentence (keys %sentences) {
  foreach my $len (1..length $sentence) {
    $sentence_prefixes{substr $sentence, 0, $len} = 1;
  }
}

# Read input plain text
my $paragraph = "";
while (defined ($_ = <>) || length $paragraph) {
  chomp;
  if (/^$/) {
    # Locate all sentences present in the paragraph
    for (my $i = 0; $i < length $paragraph; $i++) {
      next if substr $paragraph, $i, 1 =~ /\s/;
      my $sentence = "";
      for (my $j = $i; $j < length $paragraph; $j++) {
        next if substr $paragraph, $j, 1 =~ /\s/;
        $sentence .= substr $paragraph, $j, 1;
        last if not exists $sentence_prefixes{$sentence};
        print "$sentence\n" if exists $sentences{$sentence};
      }
    }

    $paragraph = "";
  } else {
    $paragraph .= "$_\n";
  }
}


# Write output CoNLL-U
