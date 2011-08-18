# $Id: delete-2.tcl,v 3.0.4.1 2000/04/28 15:09:09 carsten Exp $
set admin_id [ad_verify_and_get_user_id]

if { $admin_id == 0 } {
    ad_returnredirect "/register/"
    return
}

# we know who the administrator is

set_the_usual_form_variables

# page_id, url, deletion_reason ("spam", "dupe", "other")

set db [ns_db gethandle]

set offending_user_id [database_to_tcl_string $db "select user_id from links
where page_id = $page_id
and url = '$QQurl'"]

ns_db dml $db "delete from links 
where page_id = $page_id
and url = '$QQurl'"

set selection [ns_db 1row $db "select url_stub, nvl(page_title, url_stub) as page_title
from static_pages
where static_pages.page_id = $page_id"]
set_variables_after_query

ReturnHeaders

ns_write "[ad_admin_header "Link Deleted"]
    
<h2>Link Deleted</h2>

<hr>

The link to $url has been deleted from the database.

"

if { [mv_enabled_p] && [info exists $deletion_reason] && ![empty_string_p $deletion_reason] && $deletion_reason != "other" } {
    # this is a naughty user; let's assess a charge
    if { $deletion_reason == "spam" } {
	set amount [mv_parameter LinkSpamRate]
	set charge_type "link_spam"
	set charge_comment "SPAM: Added a link from $url_stub to $url."
    } else {
	# assume it was some kind of mistake
	set amount [mv_parameter LinkDupeRate]
	set charge_type "link_dupe"
	set charge_comment "Dupe/Mistake: Added a link from $url_stub to $url."
    }
    if { $amount > 0 } {
	ns_db dml $db "insert into  users_charges (user_id, admin_id, charge_type, amount, currency, entry_date, charge_comment)
values
($offending_user_id, $admin_id, '$charge_type', $amount, '[mv_parameter Currency]', sysdate, '[DoubleApos $charge_comment]')"
        ns_write "<p>
Charged user <a href=\"/admin/users/one.tcl?user_id=$offending_user_id\">$offending_user_id</a> ([database_to_tcl_string $db "select first_names || ' ' || last_name from users where user_id = $offending_user_id"]) [mv_parameter Currency] $amount, under category $charge_type."
    }
}


ns_write "

<p>

You can visit <a href=\"$url_stub\">$url_stub</a> if you'd like to see
how the links look now.

[ad_admin_footer]
"
