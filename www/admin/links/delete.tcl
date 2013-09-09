# /admin/links/delete.tcl

ad_page_contract {
    Delete one link from one page

    @param page_id The ID of the page on which to delete
    @param url The URL to delete
    
    @author Original Author Unknown
    @creation-date Original Date Unknown
    @cvs-id delete.tcl,v 3.3.2.6 2000/09/22 01:35:29 kevin Exp
} {
    page_id:notnull,naturalnum
    url:notnull
} 

set admin_id [ad_verify_and_get_user_id]

if { $admin_id == 0 } {
    ad_returnredirect "/register/"
    return
}

# we know who the administrator is

db_1row select_page_info "select url_stub, nvl(page_title, url_stub) as page_title
from static_pages
where static_pages.page_id = :page_id"

db_1row select_link_info "select l.user_id, l.link_title, l.link_description, l.status, l.originating_ip, l.posting_time, u.first_names, u.last_name, u.email
from links l, users u
where l.user_id = u.user_id
and l.page_id = :page_id
and l.url = :url"

db_release_unused_handles

if ![empty_string_p $originating_ip] {
    set ip_note "from <a href=\"one-ip?[export_url_vars originating_ip]\">$originating_ip</a>"
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

set page_content "[ad_admin_header "Confirm Deletion"]
    
<h2>Confirm Deletion</h2>

<hr>

<ul>
<li>from:  <a href=\"$url_stub\">$url_stub</a> ($page_title)
<li>to: <a href=\"$url\">$url</a> ($link_title)
</ul>

Added by <a
href=\"/admin/users/one?user_id=$user_id\">$first_names
$last_name</a> ($email) on [util_AnsiDatetoPrettyDate $posting_time]
$ip_note

<p>

<center>
<form method=POST action=\"delete-2\">
[export_form_vars page_id url]

<input type=submit value=\"Yes, I'm sure I want to delete this link\">

$user_charge_option

</form>
</center>

[ad_admin_footer]
"

doc_return  200 text/html $page_content