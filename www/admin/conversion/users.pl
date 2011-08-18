#!/usr/local/bin/perl

# Script to convert users from old photo.net to new ACS.
# we leave this here as an example of how to convert from a
# system that keys by email address to one that keys by user id

use strict;
use DBI;

require 'util.pl';


my $dbh = get_dbhandle("philgserver", "theolddbpassword");
my $db2 = get_dbhandle("photonet", "thedbpassword");

my %users = sql_to_hash($db2, "select email, user_id from users");
my %user_map = sql_to_hash($db2, "select email || name, user_id from user_map");


# my $sql = "select distinct poster_name name, poster_email email from philgserver.neighbor_to_neighbor
# union
# select distinct maintainer_name name, maintainer_email from philgserver.bboard_topics
# union
# select distinct name, email from philgserver.bboard
# union
# select distinct maintainer_name name, maintainer_email email from philgserver.ad_domains
# union
# select distinct name, email from philgserver.stolen_registry
# union
# select distinct name, email from philgserver.comment_comments where realm = 'philg'
# union select distinct name, email from philgserver.comment_ratings where realm = 'philg'
# union select distinct name, email from philgserver.links"
# union select distinct poster_name as name, poster_email as email from philgserver.classified_ads";
my $sql = "select distinct name, email from philgserver.comment_comments where realm = 'philg'";


my $sth = $dbh->prepare($sql) || die $dbh->errstr;
$sth->execute || die $dbh->errstr;

my $users_sth = $db2->prepare("insert into users (user_id, first_names, last_name, email, password, converted_p) values (user_id_sequence.nextval, ?, ?, ?, 'none', 't') returning user_id into ?") || die $db2->errstr;

my $user_map_sth = $db2->prepare("insert into user_map (email, name, user_id) values (?, ?, ?)") || die $db2->errstr;

while (set_query_variables($sth)) {
  no strict 'vars';
  
  $canon_email = canonicalize_email($email, $name);
  
  my ($first_names, $last_name) = parse_name($name);
  if (! $first_names) {
    $first_names = "--";
  }
  if (! $last_name) {
    $last_name = "--";
  }
  if (! $canon_email) {
    $canon_email = "no_email:$first_names:$last_name";
  }
  
  print "$email ($name) (canonical email $canon_email) ($last_name, $first_names)\n";
  
  my $user_id = $users{$canon_email};
  if (! $user_id) {
    print "  inserting into users\n";
    $users_sth->bind_param(1, $first_names);
    $users_sth->bind_param(2, $last_name);
    $users_sth->bind_param(3, $canon_email);
    $users_sth->bind_param_inout(4, \$user_id, 100);
    $users_sth->execute;
    $users{$canon_email} = $user_id;
  }
  if (! $user_map{$email . $name}) {
    print "  inserting into user_map\n";
    $user_map_sth->execute($email, $name, $user_id);
    $user_map{$email . $name} = $user_id;
  }
}

$db2->commit;
$users_sth->finish;
$sth->finish;

$dbh->disconnect;
$db2->disconnect;

sub parse_name {
  my $name = shift;
  
  $name =~ s/<[^>]+>//g;
  if ($name =~ /^(\S+),\s*(.*)\s*$/) {
    # last name first
    return ($2, $1);
  } elsif ($name =~ /^(\S+)\s+(\S+)\s*$/) {
    # first last
    return ($1, $2);
  } elsif ($name =~ /^(\S+)\s+(\S+)\s+(\S+)\s*$/) {
    # first mi last
    return ("$1 $2", $3);
  } else {
    # put it all in the first name.
    return ($name, undef);
  }
}
