# $Id: bad-password.tcl,v 3.0 2000/02/06 03:53:54 ron Exp $
set_the_usual_form_variables

# user_id
# maybe return_url (which we ignore right now)


if {[ad_parameter EmailForgottenPasswordP "" 1]} {

    set email_password_blurb "If you've forgotten your password, <a
href=\"email-password.tcl?user_id=$user_id\">ask this server to email it
to you</a>."
} else {
    set email_password_blurb ""
}

ns_return 200 text/html "[ad_header "Bad Password"]

<h2>Bad Password</h2>

in <a href=\"/index.tcl\">[ad_system_name]</a>

<hr>

The password you typed doesn't match what we have in the database.  If
you think you made a typo, please back up using your browser and
try again.

<p>

$email_password_blurb

[ad_footer]
"
