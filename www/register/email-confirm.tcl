# $Id: email-confirm.tcl,v 3.1 2000/03/10 22:39:29 lars Exp $
set_the_usual_form_variables

# rowid

set db [ns_db gethandle] 

# remove whitespace from rowid
regsub -all "\[ \t\n]+" $rowid {} rowid

# we take authorized here in case the
# person responds more than once

set selection [ns_db 0or1row $db "select user_state,
email, user_id from users 
where rowid = '[DoubleApos $rowid]'
or user_state = 'need_email_verification_and_admin_approv'
and (user_state = 'need_admin_approv'
     or user_state = 'authorized')"]


if { $selection == "" } {
    ns_db releasehandle $db
    ad_return_error "Couldn't find your record" "Row id $rowid is not in the database.  Please check your email and verifiy that you have cut and pasted the url correctly."
    return
}

set_variables_after_query


if {$user_state == "need_email_verification" || $user_state == "authorized"} {
    ns_db dml $db "update users 
set email_verified_date = sysdate, user_state = 'authorized' 
where user_id = $user_id"

    set whole_page "[ad_header "Email confirmation success"]

<h2>Your email is confirmed</h2>

at [ad_site_home_link]

<hr>

Your email has been confirmed. You may now log into
[ad_system_name].

<p>

<form action=\"user-login.tcl\" method=post>
[export_form_vars email]
<input type=submit value=\"Continue\">
</form>

<p>
Note: If you've forgotten your password, <a
href=\"email-password.tcl?user_id=$user_id\">ask this server to email it
to $email</a>.

[ad_footer]
"

} else {

    #state is need_email_verification_and_admin_approv or rejected
    if { $user_state == "rejected" } {
	ns_db dml $db "update users 
set email_verified_date = sysdate 
where user_id = $user_id"
     } elseif { $user_state == "need_email_verification_and_admin_approv" } {
	ns_db dml $db "update users 
set email_verified_date = sysdate, user_state = 'need_admin_approv' 
where user_id = $user_id"

    }

    set whole_page "[ad_header "Email confirmation success"]

<h2>Your email is confirmed</h2>

at [ad_site_home_link]

<hr>
Your email has been confirmed. You are now awaiting approval
from the [ad_system_name] administrator.

[ad_footer]"

}

ns_db releasehandle $db

ns_return 200 text/html $whole_page

