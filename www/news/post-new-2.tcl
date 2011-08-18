#
# /www/news/post-new-2.tcl
#
# display confirmation page for new news item
#
# Author: jkoontz@arsdigita.com March 8, 2000
#
# $Id: post-new-2.tcl,v 3.1.2.1 2000/04/28 15:11:14 carsten Exp $

# Note: if page is accessed through /groups pages then group_id and 
# group_vars_set are already set up in the environment by the 
# ug_serve_section. group_vars_set contains group related variables
# (group_id, group_name, group_short_name, group_admin_email, 
# group_public_url, group_admin_url, group_public_root_url,
# group_admin_root_url, group_type_url_p, group_context_bar_list and
# group_navbar_list)

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set_the_usual_form_variables
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)
# maybe return_url, name
# title, body, AOLserver ns_db magic vars that can be 
# kludged together to form release_date and expiration_date

ad_scope_error_check

set db [ns_db gethandle]
set user_id [ad_scope_authorize $db $scope all all all ]

if { $user_id == 0 } {
    ad_returnredirect "/register/index.tcl?[export_url_scope_vars]"
    return
}

set creation_ip_address [ns_conn peeraddr]

set exception_count 0
set exception_text ""

if [catch  {
    ns_dbformvalue [ns_conn form] release_date date release_date
    ns_dbformvalue [ns_conn form] expiration_date date expiration_date} errmsg] {
    incr exception_count
    append exception_text "<li>Please make sure your dates are valid."
} else {
    set expire_laterthan_future_p [database_to_tcl_string $db "select to_date('$expiration_date', 'yyyy-mm-dd')  - to_date('$release_date', 'yyyy-mm-dd')  from dual"]
    if {$expire_laterthan_future_p <= 0} {
	incr exception_count
	append exception_text "<li>Please make sure the expiration date is later than the release date."
    }
}

# now release_date and expiration_date are set

if { ![info exists title] || $title == ""} {
    incr exception_count
    append exception_text "<li>Please enter a title."
}
if { ![info exists body] || $body == "" } {
    incr exception_count
    append exception_text "<li>Please enter the full story."
}

if {$exception_count > 0} { 
    ad_scope_return_complaint $exception_count $exception_text $db
    return
}

set news_item_id [database_to_tcl_string $db "select news_item_id_sequence.nextval from dual"]

append page_content "
[ad_scope_header "Confirm" $db]
[ad_scope_page_title "Confirm" $db]

your submission to [ad_site_home_link]

<hr>

<h3>What viewers of a summary list will see</h3>

<blockquote>
$title
</blockquote>

<h3>The full story</h3>

<blockquote>

"

if { [info exists html_p] && $html_p == "t" } {
    append page_content "$body
</blockquote>

Note: if the story has lost all of its paragraph breaks then you
probably should have selected \"Plain Text\" rather than HTML.  Use
your browser's Back button to return to the submission form.
"

} else {
    append page_content "[util_convert_plaintext_to_html $body]
</blockquote>

Note: if the story has a bunch of visible HTML tags then you probably
should have selected \"HTML\" rather than \"Plain Text\".  Use your
browser's Back button to return to the submission form.  " 
}

append page_content "

<h3>Dates</h3>

<ul>
<li>will be released on [util_AnsiDatetoPrettyDate $release_date]
<li>will expire on [util_AnsiDatetoPrettyDate $expiration_date]
</ul>

<form method=post action=\"post-new-3.tcl\">
[export_form_scope_vars news_item_id]
[export_entire_form]
<center>
<input type=submit value=\"Confirm\">
</center>
</form>

[ad_scope_footer]"

ns_db releasehandle $db

ns_return 200 text/html $page_content