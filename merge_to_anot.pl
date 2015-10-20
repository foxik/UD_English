#!/usr/bin/perl
use warnings;
use strict;
use utf8;
use open qw(:std :utf8);

use List::Util;

# Read input CoNLL-U
my @conllu;
my @sentences;

my %sentences;

warn "Loading CoNLL-U";

my ($sentence, $sentence_start) = ("", 0);
while (defined ($_ = <STDIN>) || length $sentence) {
  chomp;

  my @parts = split /\t/;

  # Deal with -[LR]RB- in Form and Lemma columns.
  @parts && $parts[1] =~ s/-LRB-/(/g && $parts[2] =~ s/-lrb-/(/g;
  @parts && $parts[1] =~ s/-RRB-/)/g && $parts[2] =~ s/-rrb-/)/g;

  if (!@parts) {
    if (length $sentence) {
      push @sentences, {start=>$sentence_start, end=>$#conllu};

      my $tokens = join " ", map {$_->[1]} @conllu[$sentence_start..$#conllu];
      warn "Multiple occurrences of sentence '$sentence' with different tokens $tokens and $sentences{$sentence}->{tokens}" if exists $sentences{$sentence} && $tokens ne $sentences{$sentence}->{tokens};
      $sentences{$sentence} = {indices=>[], tokens=>$tokens} if not exists $sentences{$sentence};
      push @{$sentences{$sentence}->{indices}}, $#sentences;
    }
    $sentence = "";
    $sentence_start = scalar(@conllu) + 1;
  } else {
    $sentence .= $parts[1];
  }
  push @conllu, [@parts];
}

warn "Generating prefixes";

# Generate all sentence prefixes
my %sentence_prefixes;
foreach my $sentence (keys %sentences) {
  foreach my $len (1..length $sentence) {
    $sentence_prefixes{substr($sentence, 0, $len)} = 1;
  }
}

warn "Reading input plain text";

# Read input plain texts
my $input = "";
my @files = ();
foreach my $arg (@ARGV) {
  my $text = "";
  push @files, {name=>$arg, start=>length $input};
  open (my $f, "<", $arg) or die "Cannot open file '$arg': $!";
  while (<$f>) {
    $text .= $_;
  }
  close $f;

  $text =~ s/^\s*//s; # Remove spaces at the beginning.
  $input .= $text;
  $files[-1]->{end} = length $input;
}

warn "Locating all sentences in the input";

# Locate all sentences present in the input
my @input_sentences;
foreach (1..length $input) {
  push @input_sentences, [];
}

# Mark all possible sentences
for (my $i = 0; $i < length $input; $i++) {
  next if substr($input, $i, 1) =~ /\s/;
  my $sentence = "";
  for (my $j = $i; $j < length $input; $j++) {
    next if substr($input, $j, 1) =~ /\s/;
    $sentence .= substr $input, $j, 1;
    last if not exists $sentence_prefixes{$sentence};
    if (exists $sentences{$sentence}) {
      my $k = $j + 1;
      while ($k < length $input && substr($input, $k, 1) =~ /\s/) { $k++;}

      foreach my $index (@{$sentences{$sentence}->{indices}}) {
        push @{$input_sentences[$i]}, {index=>$index, end=>$k};
      }
    }
  }
}

# Sort the possible sentences from the longest one
for (my $i = 0; $i < $#input_sentences; $i++) {
  $input_sentences[$i] = [sort { $b->{end} <=> $a->{end} } @{$input_sentences[$i]}];
}

# Assign the sentences 1:1
my @input_sentence;
my @assigned_sentence = (0) x @sentences;

sub assign_sentences {
  my ($i) = @_;

  # End condition
  if ($i >= length $input) {
    my ($assigned, $total) = (List::Util::sum(@assigned_sentence), scalar @sentences);
    warn "Reached end of input, but assigned only $assigned out of $total sentences!" if $assigned != $total;
    return 1;
  }

  my $tried_end = 1 + length $input;
  foreach my $sentence (@{$input_sentences[$i]}) {
    my ($index, $end) = ($sentence->{index}, $sentence->{end});
    next if $assigned_sentence[$index] || $end == $tried_end;
    $assigned_sentence[$index] = 1;
    $input_sentence[$i] = {index=>$index, end=>$end};
    return 1 if assign_sentences($end);
    $tried_end = $end;
    $assigned_sentence[$index] = 0;
  }

  return 0;
}

warn "Assigning sentences";

die "Cannot find sentence assignment" if not assign_sentences(0);

foreach my $file (@files) {
  my ($file_name, $file_start, $file_end) = ($file->{name}, $file->{start}, $file->{end});
  open (my $f, ">", "$file_name.spaces") or die "Cannot open file $file_name.spaces: $!";
  for (my $start = $file_start; $start < $file_end; ) {
    my ($index, $end) = ($input_sentence[$start]->{index}, $input_sentence[$start]->{end});
    warn "Sentence going through files at $file_name sentence $sentences{$index}->{tokens}" if $end > $file_end;

    my $raw = substr $input, $start, $end - $start + 1; # Ane additional character for SpaceAfter of last token
    my ($token_start, $token_end) = ($sentences[$index]->{start}, $sentences[$index]->{end});
    for (my $token = $token_start; $token <= $token_end; $token++) {
      my $remove_token_re = "^\\s*" . join("\\s*", map { "\Q$_\E" } split //, $conllu[$token]->[1]);
      die "Cannot match sentence $sentence at point $raw, file $file_name" if $raw !~ s/$remove_token_re//s;
      print $f "$conllu[$token]->[1]\t" . ($raw =~ /^\s/s ? "" : "SpaceAfter=No") . "\n";
    }
    print $f "\n";

    die "Cannot match sentence $index at point $raw, file $file_name" if $raw !~ /^\s*.?$/s;
    $start = $end;
  }
  close $f;
}
