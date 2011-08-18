#
# util.pl
#
# by jsc@arsdigita.com
# 
# allegedly good for making Perl DBI scripts that mung data in Oracle
# 

sub get_dbhandle {
  my ($username, $passwd) = @_;
  my $dbh = DBI->connect('dbi:Oracle:', $username, $passwd) || die "Couldn't connect";
  $dbh->{AutoCommit} = 0;
  $dbh->{LongReadLen} = 4000000;
  $dbh->{LongTruncOk} = 0;
  $dbh;
}

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

# Attempt to clean up random email crap. If there was no email specified,
# use the name argument to create a class of anonymous users.
sub canonicalize_email {
  my ($email, $name) = shift;
  $email = lc($email);
  $email =~ s/^<(.*)>\s*$/\1/;
  $email =~ s/<[^>]+>//gi;
  $email =~ s/remove-nospam\.//gi;
  $email =~ s/nospam\.//gi;
  $email =~ s/\.nospam//gi;
  $email =~ s/\*nospam//gi;
  $email =~ s/_no_spam//gi;
  $email =~ s/nospam//gi;

  if (! $email) {
    my ($first_names, $last_name) = parse_name($name);
    if (! $first_names) {
      $first_names = "--";
    }
    if (! $last_name) {
      $last_name = "--";
    }
    $email = "no_email:$first_names:$last_name";
  }
  
  $email;
}

sub set_query_variables {
  my $sth = shift;
  my @field_values = $sth->fetchrow_array;
  if (! @field_values) {
    return undef;
  }
  my @field_names = @{ $sth->{NAME} };
  my $callpack = caller;
  no strict 'refs';
  
  my $fieldcount = scalar(@field_names);
  for (my $i = 0; $i < $fieldcount; $i++) {
    my $var = lc($field_names[$i]);
    my $value = $field_values[$i];
    *{"${callpack}::$var"} = \$value;
  }
  1;
}

# Takes a select statement that returns two fields, returns a hash
# table that uses the first column as the key and the second as the value.
sub sql_to_hash {
  my ($dbh, $sql) = @_;
  my $sth = $dbh->prepare($sql) || die $dbh->errstr;
  my @field_values;
  my %rethash;

  $sth->execute || die $dbh->errstr;
  while (my ($key, $value) = $sth->fetchrow_array) {
    $rethash{$key} = $value;
  }
  $sth->finish;
  %rethash;
}

1;
