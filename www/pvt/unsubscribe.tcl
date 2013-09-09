# unsubscribe.tcl

ad_page_contract {
    Unsubscribe from the ACS.
    @cvs-id unsubscribe.tcl,v 3.2.6.5 2000/09/22 01:39:12 kevin Exp
}

set user_id [ad_get_user_id]

if { ![db_0or1row pvt_unsubscribe_status_check {
    select on_vacation_until, on_vacation_p(on_vacation_until) as on_vacation_p 
    from users
    where user_id = :user_id
}]} {
    ad_return_error "Couldn't find your record" "User id $user_id is not in the database.  This is probably out programming bug."
    return    
}

append page_content "[ad_header "Confirm Unsubscribe"]

<h2>Confirm</h2>

that you'd like to unsubscribe from [ad_site_home_link]

<hr>
"

if { $on_vacation_p == "t" } {
    append page_content "You are current marked as being on vacation until [util_AnsiDatetoPrettyDate $on_vacation_until].  If you'd like to start receiving email alerts again, just <a href=\"set-on-vacation-to-null\">tell us that you're back</a>."
} else {
    append page_content "If you are interested in this community but wish to stop receiving
email then you might want to 

<ul>
<li>tell the system that you're going on vacation until 
<form method=get action=set-on-vacation-until>
[philg_dateentrywidget_default_to_today on_vacation_until]
<input type=submit value=\"Put email on hold\">
</form>
<p>
"
}

if {[db_0or1row dont_spam_me_p_qry {
    select dont_spam_me_p from users_preferences where user_id = :user_id
}]} {
    if { $dont_spam_me_p != "t" } {
	append page_content "
<li>The system is currently set to send you email notifications. Click here to  <a href=\"toggle-dont-spam-me-p\">tell the system not to send you any email notifications</a>.
"
    } else {
	append page_content "
<li>The system is currently set to <i>not</i> send you any email notifications. Click here <a href=\"toggle-dont-spam-me-p\">allow system to send you email notifications</a>.
"	
    }
}


append page_content "

</ul>
<p>

However, if you've totally lost interest in this community or topic,
then you can <a href=\"unsubscribe-2\">ask the server to mark your
account as deleted</a>.

[ad_footer]"

doc_return  200 text/html $page_content
