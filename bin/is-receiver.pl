#!/usr/local/bin/perl
# receiver.pl
# Part of the ArsDigita MTA Monitor
# You will have to CUSTOMIZE this script!  See below.

# This script is spawned by the local MTA in response to an incoming
# bounced emailet from the monitored server.  It simply extracts the
# emailet_id from the Subject line of the message and passes it to
# receiver.tcl, which is a Tcl script sitting in the Web server and
# talking to the database.

# I offer you choice of using either lynx or wget to talk to the
# Web server. I didn't use the Perl's LWP library because the latter was
# not installed on the system I developed this.  If you know Perl it
# should take you about 5 minutes to add a LWP version.

#############################   Customize this!  ### ########################
## Uncomment one of these two:
$web_client_name = 'wget';
#$web_client_name = 'lynx';

$web_client_dir = '/usr/local/bin';
$localhost='www.arsdigita.com'; # Set this to hostame or IP (port num.
                                # is optional) where the local AOLserver with
                                # ArsDigita MTA Monitor listens:
$receiver_script='/ischecker/receiver.tcl'; # This is the full path to receiver.tcl
                                # relative to the page root of your web server
                                # including the leading "/".
##############################################################################

############## You will rarely want to customize some of this ################

## These two options will work only if you are using wget:
$tries = 10;   # Try ten times (maybe AOLserver is just being rebooted)...
$wait = 5;     # With five seconds between attemps.
$debug = 1;
##############################################################################

open(LOGFILE, ">>/tmp/receiver.log") if $debug;

if ($web_client_name =~ 'wget') {

   $cl_options = "-S -O - --tries=$tries --wait=$wait --proxy=off";
   # Wget will retry $tries times with $wait seconds breaks
   # in between.  If it doesn't get the HTTP status of 2xx
   # its exit value will be nonzero so that the local mailer
   # which spawned this procedure will know that something
   # has gone wrong and will be able to send a notification email.
   # The -O - option tells wget to send the output to the standard
   # output rather than to save it to a file.  The -S options tells
   # wget to output also the HTTP headers.  Useful for debugging if
   # something goes wrong.
} elsif ($web_client_name =~ 'lynx') {
   $cl_options = '-source';
}

## Grab the emailet_id from the subject line:
while (<>) {
    chop;
    if (/^$/) {last};         # Blank line means end of headers.
    s/^Subject: .*emailet_id=(.*)$/$1/ && ($emailet_id=$_);
}

print LOGFILE "emailet_id=$emailet_id\n" if $debug;

system "$web_client_dir/$web_client_name $cl_options http://$localhost/$receiver_script?emailet_id=$emailet_id";
