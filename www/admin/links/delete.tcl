# $Id: delete.tcl,v 3.0.4.1 2000/04/28 15:09:09 carsten Exp $
set admin_id [ad_verify_and_get_user_id]

if { $admin_id == 0 } {
    ad_returnredirect "/register/"
    return
}

# we know who the administrator is

set_the_usual_form_variables

# page_id, url

set db [ns_db gethandle]

set selection [ns_db 1row $db "select url_stub, nvl(page_title, url_stub) as page_title
from static_pages
where static_pages.page_id = $page_id"]
set_variables_after_query

set selection [ns_db 1row $db "select l.user_id, l.link_title, l.link_description, l.status, l.originating_ip, l.posting_time, u.first_names, u.last_name, u.email
from links l, users u
where l.user_id = u.user_id
and l.page_id = $page_id
and l.url = '$QQurl'"]
set_variables_after_query


if ![empty_string_p $originating_ip] {
    set ip_note "from <a href=\"one-ip.tcl?[export_url_vars originating_ip]\">$originating_ip</a>"
} else {
    set ip_note ""
}

if [mv_enabled_p] {
    set user_charge_option "<h3>Charge this user for his or her sins?</h3>

<select name=deletion_reason>
<option value=\"\">Don't charge</option>
<option value=\"dupe\">Dupe</option>
<option value=\"spam\">Spam</option>
</select>

"
} else {
    set user_charge_option ""
}

ns_return 200 text/html "[ad_admin_header "Confirm Deletion"]
    
<h2>Confirm Deletion</h2>

<hr>

<ul>
<li>from:  <a href=\"$url_stub\">$url_stub</a> ($page_title)
<li>to: <a href=\"$url\">$url</a> ($link_title)
</ul>

Added by <a
href=\"/admin/users/one.tcl?user_id=$user_id\">$first_names
$last_name</a> ($email) on [util_AnsiDatetoPrettyDate $posting_time]
$ip_note

<p>

<center>
<form method=POST action=\"delete-2.tcl\">
[export_form_vars page_id url]

<input type=submit value=\"Yes, I'm sure I want to delete this link\">

$user_charge_option

</form>
</center>

[ad_admin_footer]
"

