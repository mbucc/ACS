# $Id: post-new-3.tcl,v 3.1 2000/03/11 09:03:43 aileen Exp $
# File:     /calendar/item.tcl
# Date:     1998-11-18
# Contact:  philg@mit.edu, ahmeds@arsdigita.com
# Purpose:  give the user a chance to confirm his or her posting
#           this is where we expect most entry errors to be caught
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set_the_usual_form_variables 0
# title, body, AOLserver ns_db magic vars that can be 
# kludged together to form release_date and expiration_date
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)

ad_scope_error_check

set db [ns_db gethandle]
ad_scope_authorize $db $scope all group_member registered

set creation_ip_address [ns_conn peeraddr]

set exception_count 0
set exception_text ""

if [catch  { ns_dbformvalue [ns_conn form] start_date date start_date
             ns_dbformvalue [ns_conn form] end_date date end_date } errmsg] {
    incr exception_count
    append exception_text "<li>Please make sure your dates are valid."
} else {

    # we assume that the event ends at the very end of the end_date
    # we have to do the bogus 1000* and then rounding because of Stupid Oracle
    # driver truncation errors (doesn't like big fractions)
    set expire_laterthan_future_p [database_to_tcl_string $db "select round(1000*(to_date('$end_date  11:59:59', 'YYYY-MM-DD HH24:MI:SS')  - to_date('$start_date', 'YYYY-MM-DD')))  from dual"]
    if {$expire_laterthan_future_p <= 0} {
	incr exception_count
	append exception_text "<li>Please make sure the end date is later than the start date."
    }
}

# now start_date and end_date are set


if { ![info exists title] || [empty_string_p $title] } {
    incr exception_count
    append exception_text "<li>Please enter a title."
}
if { ![info exists body] || [empty_string_p $body] } {
    incr exception_count
    append exception_text "<li>Please enter the full event description."
}

if { [info exists event_email] && ![empty_string_p $event_email] && ![philg_email_valid_p $event_email] } {
    incr exception_count
    append exception_text "<li>The event contact email address that you typed doesn't look right to us.  Examples of valid email addresses are 
<ul>
<li>Alice1234@aol.com
<li>joe_smith@hp.com
<li>pierre@inria.fr
</ul>
"
}

if {$exception_count > 0} { 
    ad_scope_return_complaint $exception_count $exception_text $db
    return
}


set calendar_id [database_to_tcl_string $db "select calendar_id_sequence.nextval from dual"]

ReturnHeaders

ns_write "

[ad_scope_header "Confirm" $db]
[ad_scope_page_title "Confirm" $db]
[ad_scope_context_bar_ws_or_index [list "index.tcl?[export_url_scope_vars]" [ad_parameter SystemName calendar "Calendar"]] "Confirm"]

<hr>
[ad_scope_navbar]

<h3>What viewers of a summary list will see</h3>

<blockquote>
$title
</blockquote>

<h3>The full description</h3>

<blockquote>

"

if { [info exists html_p] && $html_p == "t" } {
    ns_write "$body
</blockquote>

Note: if the description has lost all of its paragraph breaks then you
probably should have selected \"Plain Text\" rather than HTML.  Use
your browser's Back button to return to the submission form.
"

} else {
    ns_write "[util_convert_plaintext_to_html $body]
</blockquote>

Note: if the description has a bunch of visible HTML tags then you probably
should have selected \"HTML\" rather than \"Plain Text\".  Use your
browser's Back button to return to the submission form.  " 
}


ns_write "

<h3>Dates</h3>

<ul>
<li>will start on [util_AnsiDatetoPrettyDate $start_date]
<li>will end on [util_AnsiDatetoPrettyDate $end_date]
</ul>

<h3>Contact Information</h3>

Here's where we will tell readers to go for more information:

<ul>
<li>Email: "

if { ![info exists event_email] || [empty_string_p $event_email] } {
    ns_write "no address supplied"
} else {
    ns_write $event_email
}

ns_write "<li>Url: "

if { [info exists event_url] && ![philg_url_valid_p $event_url] } {
    # not an exception but user did not type a valid URL (presumably left it blank)
    ns_write "no URL supplied"
} else {
    ns_write "<a href=\"$event_url\">$event_url</a>\n"
}

ns_write "


</ul>


<form method=post action=\"post-new-4.tcl?[export_url_scope_vars]\">
[export_form_scope_vars calendar_id category]
[export_entire_form]
<center>
<input type=submit value=\"Confirm\">
</center>
</form>


[ad_scope_footer]"


