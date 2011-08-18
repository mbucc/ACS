#!/usr/local/bin/perl
#
# Respond to incoming mail message on STDIN
#
# hqm@ai.mit.edu
#
# This script does the following:
#
sub usage () {
    print '
  usage: queue_message.pl db_datasrc db_user db_passwd destaddr

  Inserts the data from stdin into a queue table.

  Assumes the following table and sequence are defined in the db:

    create table incoming_email_queue (
            id          integer primary key,
            destaddr    varchar(256),
            content             clob,           -- the entire raw message content
                                            -- including all headers
            arrival_time        date
    );

    create sequence incoming_email_queue_sequence;

';
}

use DBI;
#use Mail::Address;

use DBD::Oracle qw(:ora_types);

#need for archive file

use Time::localtime;
use IO::File;

################################################################
# Global Definitions

$db_datasrc        = shift;
$db_user           = shift;
$db_passwd         = shift;
$destaddr          = shift;

$DEBUG = 1;
$debug_logfile = "/tmp/intranet-mailhandler-log.txt"; # 

# Oracle access
$ENV{'ORACLE_HOME'} = "/ora8/m01/app/oracle/product/8.1.5";
$ENV{'ORACLE_BASE'} = "/ora8/m01/app/oracle";
$ENV{'ORACLE_SID'} = "ora8";

$archive_mail_directory = "/web/intranet/mail-archive";

if (!defined $db_datasrc) {
    $db_datasrc = 'dbi:Oracle:';
}

if (!defined $db_user) {
    usage();
    die("You must pass a db user in the command line");
}

if (!defined $db_passwd) {
    usage();
    die("You must pass a db passwd in the command line");
}



#################################################################
## Snarf down incoming msg on STDIN
#################################################################

while (<>) {
    $content .= $_; 
}


if ($DEBUG) {
    open (LOG, ">>$debug_logfile");
    debug("================================================================\n");
    debug("Recevied content:\n$content\n");
    debug("================================================================\n");
}

# save a clean copy in filesystem.

system("chmod 666 $debug_logfile");

my $archive = open_archive_file();
$archive->print( $content );
$archive->close();

# Open the database connection.
$dbh = DBI->connect($db_datasrc, $db_user, $db_passwd)
  || die "Couldn't connect to database";
$dbh->{AutoCommit} = 1;
# This is supposed to make it possible to write large CLOBs

$dbh->{LongReadLen} = 2**20;   # 1 MB max message size 
$dbh->{LongTruncOk} = 0;   


debug("Status: inserting into email queue\n");
$h = $dbh->prepare(qq[INSERT INTO incoming_email_queue (id, destaddr,  content, arrival_time) VALUES (incoming_email_queue_sequence.nextval, '$destaddr', ?, sysdate)]);


$h->bind_param(1, $content, { ora_type => ORA_CLOB, ora_field=>'content' });

if (!$h->execute) {
    die "Unable to open cursor:\n" . $dbh->errstr;
}
$h->finish;

$dbh->disconnect;
debug("[closing log]\n");
if ($DEBUG) { close LOG; }

sub debug () {
    my ($msg) = @_;
    print LOG $msg;
}

sub open_archive_file () { 
    my $fh;
    my $name;
    my $i = 0;
    my $tm = localtime;
    my $today = sprintf("/%04d%02d%02d:%02d:%02d:%02d.", ($tm->year + 1900), $tm->mon + 1, $tm->mday, $tm->hour, $tm->min, $tm->sec);

    do { $name = "$archive_mail_directory$today$destaddr.$i";
         $i++;
     } 
    until $fh = IO::File->new($name, O_RDWR|O_CREAT|O_EXCL);

    return $fh;
}
