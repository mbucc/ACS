#!/usr/local/bin/perl

# Useful little script to dump a message to a file for debugging.

use DBI;
use DBD::Oracle;
use strict;


if (scalar(@ARGV) != 1) {
  die "Usage: $0 msg_id\n";
}

my $msg_id = $ARGV[0];

my $dbh = DBI->connect("dbi:Oracle:", 'wmail/wmailsucks', '') || die $DBI::errstr;

$dbh->{RaiseError} = 1;
$dbh->{LongReadLen} = 10000000;
my $sth = $dbh->prepare("select name || ': ' || value 
from wm_headers
where msg_id = $msg_id");

$sth->execute;

while (my @row = $sth->fetchrow()) {
  print "$row[0]\n";
}
print "\n";

$sth->finish;

$sth = $dbh->prepare("select body
from wm_messages
where msg_id = $msg_id");

$sth->execute;

my @row = $sth->fetchrow();

print $row[0];

$sth->finish;
$dbh->disconnect;
