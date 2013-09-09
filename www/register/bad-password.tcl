# /www/register/bad-password.tcl

ad_page_contract {
    Informs the user that they have typed in a bad password.
    @cvs-id bad-password.tcl,v 3.2.2.4 2000/09/22 01:39:14 kevin Exp
} {
    {user_id:naturalnum}
    {return_url ""}
}

if {[ad_parameter EmailForgottenPasswordP "" 1]} {

    set email_password_blurb "<p>If you've forgotten your password, you can
    <a href=email-password?user_id=$user_id>ask this server to email it to you</a>."
} else {
    set email_password_blurb ""
}

doc_return  200 text/html "
[ad_header "Bad Password"]

<h2>Bad Password</h2>

in <a href=\"/index\">[ad_system_name]</a>

<hr>

<p>The password you typed doesn't match what we have in the database.
If you think you made a typo, please back up using your browser and
try again.</p>

$email_password_blurb

[ad_footer]
"
