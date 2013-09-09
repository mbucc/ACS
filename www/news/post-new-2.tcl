# /www/news/post-new-2.tcl
#

ad_page_contract {
    display confirmation page for new news item

    @author jkoontz@arsdigita.com
    @creation-date March 8, 2000
    @cvs-id post-new-2.tcl,v 3.4.2.11 2001/01/09 21:52:45 khy Exp

    Note: if page is accessed through /groups pages then group_id and 
    group_vars_set are already set up in the environment by the 
    ug_serve_section. group_vars_set contains group related variables
    (group_id, group_name, group_short_name, group_admin_email, 
    group_public_url, group_admin_url, group_public_root_url,
    group_admin_root_url, group_type_url_p, group_context_bar_list and
    group_navbar_list)
} {
    scope:optional
    user_id:integer,optional
    group_id:integer,optional
    on_which_group:integer,optional
    on_what_id:integer,optional
    return_url:optional
    name:optional
    title:html,notnull
    body:html,notnull
    {html_p "f"}
}


if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

# also AOLserver ns_db magic vars that can be 
# kludged together to form release_date and expiration_date

ad_scope_error_check


set user_id [ad_scope_authorize $scope all all all]

if { $user_id == 0 } {
    ad_returnredirect "/register/?[export_url_vars]"
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
    set expire_laterthan_future_p [db_string news_expire_get "select to_date(:expiration_date, 'yyyy-mm-dd') - to_date(:release_date, 'yyyy-mm-dd') from dual"]
    if {$expire_laterthan_future_p <= 0} {
	incr exception_count
	append exception_text "<li>Please make sure the expiration date is later than the release date."
    }
}

# now release_date and expiration_date are set

if { ![info exists title] || [empty_string_p $title] } {
    incr exception_count
    append exception_text "<li>Please enter a title."
}
if { ![info exists body] || [empty_string_p $body] } {
    incr exception_count
    append exception_text "<li>Please enter the full story."
}

if {$exception_count > 0} { 
    ad_scope_return_complaint $exception_count $exception_text
    return
}

set news_item_id [db_string news_id_get "select news_item_id_sequence.nextval from dual"]
db_release_unused_handles


set page_content "
[ad_scope_header "Confirm"]
[ad_scope_page_title "Confirm"]

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

<form method=post action=\"post-new-3\">
[export_form_vars -sign news_item_id]
[export_entire_form]
<center>
<input type=submit value=\"Confirm\">
</center>
</form>

[ad_scope_footer]"



doc_return  200 text/html $page_content


