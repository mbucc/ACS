#!/usr/local/bin/perl

# parameter-differences.pl
#
# by jsc@arsdigita.com in October 1999
#
# Compares two ArsDigita System "ad.ini" parameter files
# and prints out a human-readable report of differences.
# This is useful during version upgrades of the ACS.

use strict;

my $usage = "Usage: $0 <first file> <second file>\n";

if (scalar(@ARGV) != 2) {
  die $usage;
}

my $first_file = $ARGV[0];
my $second_file = $ARGV[1];

if (! -f $first_file || ! -f $second_file) {
  die $usage;
}


# Basic idea: run through both files, record each parameter in a hash
# table as "section:parameter" (e.g., SystemName under
# [ns/server/yourservername/acs] would be ":SystemName"; Administrator
# under [ns/server/yourservername/acs/portals] would be
# "portals:Administrator"). The two hash tables are unioned together,
# and whatever is in the union and not in each file is reported.

my %union;
my %f1_params;
my %f2_params;

%f1_params = read_parameter_file($first_file);
%f2_params = read_parameter_file($second_file);
%union = union_hashes(\%f1_params, \%f2_params);

print "$first_file:\n";
report_difference(\%union, \%f1_params);

print "\n\n$second_file:\n";
report_difference(\%union, \%f2_params);

sub read_parameter_file {
  my %params;
  my ($file_name) = shift;
  
  my $section;
  my $parameter;

  open(F, $file_name) || die $!;
  while (<F>) {
    next if /^\s*$/o;
    if (m,^\[ns/server/[^/]+/acs/?([^\]]*),) {
      $section = $1;
    } elsif (/^\s*;?\s*([A-Za-z0-9]+)=(.*)$/) {
      $parameter = $1;
      $params{"$section:$parameter"} = 1;
    }
  }
  close F;
  return %params;
}


# Returns a union of the keys of the two argument hashes.
# The values are unimportant.
sub union_hashes {
  my %union;
  my $h1_ref = shift;
  my $h2_ref = shift;

  foreach my $key (keys(%$h1_ref), keys(%$h2_ref)) {
    $union{$key} = 1;
  }
  return %union;
}

# Reports keys in first hash argument which are not in the second.
sub report_difference {
  my $h1_ref = shift;
  my $h2_ref = shift;

  foreach my $key (sort keys %$h1_ref) {
    if (!defined($$h2_ref{$key})) {
      print "* $key\n";
    }
  }
}
