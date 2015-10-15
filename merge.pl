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
    $sentence_prefixes{substr($sentence, 0, $len)} = 1;
  }
}

# Prepare votes for reconstructed spaces
my @conllu_space_yes = (0) x @conllu;
my @conllu_space_no = (0) x @conllu;

# Read input plain text
my $paragraph = "";
while (defined ($_ = <>) || length $paragraph) {
  chomp;
  if (/^$/) {
    # Locate all sentences present in the paragraph
    my @sentence_starts = (0) x length $paragraph;
    my @sentence_ends = (0) x length $paragraph;
    for (my $i = 0; $i < length $paragraph && substr($paragraph, $i, 1) =~ /\s/; $i++) { $sentence_ends[$i] = 1; }
    for (my $i = length($paragraph) - 1; $i >= 0 && substr($paragraph, $i, 1) =~ /\s/; $i--) { $sentence_starts[$i] = 1; }

    # Mark all possible starts and ends
    for (my $i = 0; $i < length $paragraph; $i++) {
      next if substr($paragraph, $i, 1) =~ /\s/;
      my $sentence = "";
      for (my $j = $i; $j < length $paragraph; $j++) {
        next if substr($paragraph, $j, 1) =~ /\s/;
        $sentence .= substr $paragraph, $j, 1;
        last if not exists $sentence_prefixes{$sentence};
        if (exists $sentences{$sentence}) {
          $sentence_starts[$i] = 1; for (my $k = $i - 1; $k >= 0 && substr($paragraph, $k, 1) =~ /\s/; $k--) { $sentence_starts[$k] = 1; }
          $sentence_ends[$j] = 1; for (my $k = $j + 1; $k < length $paragraph && substr($paragraph, $k, 1) =~ /\s/; $k++) { $sentence_ends[$k] = 1; }
        }
      }
    }

    # Fill spaces in all CoNLL-U occurrences of the found sentences
    for (my $i = 0; $i < length $paragraph; $i++) {
      next if substr($paragraph, $i, 1) =~ /\s/;
      next if $i > 0 && !$sentence_ends[$i - 1];
      my $sentence = "";
      for (my $j = $i; $j < length $paragraph; $j++) {
        next if substr($paragraph, $j, 1) =~ /\s/;
        $sentence .= substr $paragraph, $j, 1;
        last if not exists $sentence_prefixes{$sentence};
        if (exists $sentences{$sentence} && ($j + 1 == length $paragraph || $sentence_starts[$j+1])) {
          # Fill spaces in all CoNLL-U occurrences of the found sentence
          foreach my $range (@{$sentences{$sentence}->{ranges}}) {
            my ($start, $end) = ($range->{start}, $range->{end});
            my $raw = substr($paragraph, $i, $j - $i + 1 + 1); # Add one additional character for SpaceAfter of last token

            for (my $i = $start; $i <= $end; $i++) {
              my $remove_token_re = "^\\s*" . join("\\s*", map { "\Q$_\E" } split //, $conllu[$i]->[1]);
              if ($raw !~ s/$remove_token_re//) {
                warn "Cannot match sentence $sentence at point $raw, range $start - $end";
                last;
              }
              ($raw =~ /^\s/ ? \@conllu_space_yes : \@conllu_space_no)->[$i]++;
            }
          }
        }
      }
    }

    $paragraph = "";
  } else {
    $paragraph .= "$_\n";
  }
}

# Write output CoNLL-U
for (my $i = 0; $i < @conllu; $i++) {
  my @parts = @{$conllu[$i]};

  if (@parts) {
    $parts[1] =~ s/\(/-LRB-/g && $parts[2] =~ s/\(/-lrb-/g;
    $parts[1] =~ s/\)/-RRB-/g && $parts[2] =~ s/\)/-rrb-/g;
    warn "Not found token $parts[1] number $i" if $conllu_space_yes[$i] == 0 && $conllu_space_no[$i] == 0;
    warn "Multiple yes/no space votes ($conllu_space_yes[$i]/$conllu_space_no[$i]) for token $parts[1] number $i" if $conllu_space_yes[$i] > 0 && $conllu_space_no[$i] > 0;
    $parts[9] = "SpaceAfter=No" . ($parts[9] eq "_" ? "" : "|$parts[9]") if $conllu_space_no[$i] > $conllu_space_yes[$i];
    print join("\t", @parts) . "\n";
  } else {
    print "\n";
  }
}
