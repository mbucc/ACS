# www/calendar/post-new-3.tcl
ad_page_contract {
    Step 3/4 in adding a new calendar item
    Confirmation

    Number of queries: 2

    @author Philip Greenspun (philg@mit.edu)
    @author Sarah Ahmed (ahmeds@arsdigita.com)
    @creation-date 1998-11-18
    @cvs-id post-new-3.tcl,v 3.3.2.8 2001/01/10 16:30:57 khy Exp
  
} {
    {category_id:naturalnum}
    {category}
    {title}
    {body:html}
    {html_p}
    {event_url}
    {event_email}
    {scope public}
    {user_id:naturalnum ""}
    {group_id:naturalnum ""}
    {on_what_id:naturalnum ""}
    {on_which_group:naturalnum ""}
}

ad_scope_error_check

ad_scope_authorize $scope all group_member registered


if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}


set creation_ip_address [ns_conn peeraddr]


## Check for Naughty Input
if { $html_p && ![empty_string_p [ad_check_for_naughty_html $body]] } {

    set naughty_tag_list [ad_parameter_all_values_as_list NaughtyTag antispam]
    set naughty_tag_string [join $naughty_tag_list " "]
    ad_scope_return_complaint 1 "You attempted to submit one of these forbidden HTML tags: $naughty_tag_string"
    return
}



set exception_count 0
set exception_text ""

if [catch  { 
    
    ## Can we make this obsolete? -MJS

    ns_dbformvalue [ns_conn form] start_date date start_date 
    ns_dbformvalue [ns_conn form] end_date date end_date 
    
} errmsg] {
    
    incr exception_count
    append exception_text "<li>Please make sure your dates are valid."
    
} else {
    
    # we assume that the event ends at the very end of the end_date
    # we have to do the bogus 1000* and then rounding because of Stupid Oracle
    # driver truncation errors (doesn't like big fractions)

    set query_expire "select round(1000*(to_date('$end_date  11:59:59', 'YYYY-MM-DD HH24:MI:SS')  - to_date('$start_date', 'YYYY-MM-DD')))  from dual"

    set expire_laterthan_future_p [db_string expire $query_expire]

    if {$expire_laterthan_future_p <= 0} {
	incr exception_count
	append exception_text "<li>Please make sure the end date is later than the start date."
    }
}


set calendar_id [db_nextval "calendar_id_sequence"]

db_release_unused_handles


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
    ad_scope_return_complaint $exception_count $exception_text
    return
}


set page_content "

[ad_scope_header "Confirm"]
[ad_scope_page_title "Confirm"]
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
    append page_content "$body
</blockquote>

Note: if the description has lost all of its paragraph breaks then you
probably should have selected \"Plain Text\" rather than HTML.  Use
your browser's Back button to return to the submission form.
"

} else {
    append page_content "[util_convert_plaintext_to_html $body]
</blockquote>

Note: if the description has a bunch of visible HTML tags then you probably
should have selected \"HTML\" rather than \"Plain Text\".  Use your
browser's Back button to return to the submission form.  " 
}

append page_content "

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
    append page_content "no address supplied"
} else {
    append page_content $event_email
}

append page_content "<li>Url: "

if { [info exists event_url] && ![philg_url_valid_p $event_url] } {
    # not an exception but user did not type a valid URL (presumably left it blank)
    append page_content "no URL supplied"
} else {
    append page_content "<a href=\"$event_url\">$event_url</a>\n"
}

append page_content "

</ul>

<form method=post action=\"post-new-4?\">
[export_form_scope_vars]
[export_form_vars -sign calendar_id]
[ns_set delkey [ns_getform] scope]
[export_entire_form]
<center>
<input type=submit value=\"Confirm\">
</center>
</form>

[ad_scope_footer]"

doc_return  200 text/html $page_content

## END FILE post-new-3.tcl










