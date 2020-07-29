#!/usr/bin/perl

#
# commit hook to check IPv6 literals are capitalized
#

use strict;
use Getopt::Long;
use Term::ANSIColor;

# from Regexp::IPv6
my $IPv4 =
    "((25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.]"
  . "(25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.]"
  . "(25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.]"
  . "(25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2}))";
my $G = "[0-9a-fA-F]{1,4}";
my @tail = (":",
            "(:($G)?|$IPv4)",
            ":($IPv4|$G(:$G)?|)",
            "(:$IPv4|:$G(:$IPv4|(:$G){0,2})|:)",
            "((:$G){0,2}(:$IPv4|(:$G){1,2})|:)",
            "((:$G){0,3}(:$IPv4|(:$G){1,2})|:)",
            "((:$G){0,4}(:$IPv4|(:$G){1,2})|:)"
           );
my $IPv6_re = $G;
$IPv6_re = "$G:($IPv6_re|$_)" for @tail;
$IPv6_re = qq/:(:$G){0,5}((:$G){1,2}|:$IPv4)|$IPv6_re/;
$IPv6_re =~ s/\(/(?:/g;

# disable colors if not connected to a terminal
$ENV{'ANSI_COLORS_DISABLED'} = 1 unless -t STDERR;

my @errs;
my $fix;
GetOptions('fix!' => \$fix) || usage();
$^I = '*' if $fix;
usage() unless scalar @ARGV;

# check each file
while (<>) {
  if (/($IPv6_re)/ and $1 =~ /[A-F]/) {

    # for each IP in a line, highlight each set of capital hex chars
    (my $line = $_) =~ s{$IPv6_re}{
                          $& =~ s{[A-F]+}
                          {colored($&,'on_red')}ger
                        }ge;

    push @errs, colored("$ARGV line $.:", 'green'), $line;

    # downcase all IPv6 addresses on line
    s/$IPv6_re/lc($&)/ge if $fix;
  }
} continue {
  print if $fix;
}

# output any errors
if (scalar @errs) {
  print STDERR colored(  "Literal IPv6 address with capital hex letters "
                       . ($fix ? "fixed" : "found")
                       . ":", 'red'), "\n";
  print STDERR @errs;
  exit 1 unless $fix;
}

sub usage {
  print STDERR "$0 [--fix|--nofix] [files...]\n";
  exit 1;
}