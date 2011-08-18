# $Id: add-alert-2.tcl,v 3.0 2000/02/06 03:32:09 ron Exp $
set_the_usual_form_variables

# topic, topic_id, frequency, maybe keywords

set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}

if { [bboard_get_topic_info] == -1 } {
    return
}


ad_get_user_info


set exception_text ""
set exception_count 0

# we should add some tests for various things here

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text 
    return
}

set extra_columns ""
set extra_values ""
set keyword_user_report_line ""
if { [info exists keywords] && $keywords != "" } {
    # we have a keyword-limited search
    set extra_columns ", keywords"
    set extra_values ", '$QQkeywords'"
    set keyword_user_report_line "<li>Keywords:  \"$keywords\""
}

set insert_sql "insert into bboard_email_alerts ( user_id, topic_id, frequency $extra_columns )
values
( $user_id, $topic_id, '$QQfrequency' $extra_values )"

if [catch { ns_db dml $db $insert_sql } errmsg] {
    # something went wrong 
    ad_return_error "Insert failed" "We failed to insert your into our system.

<p>

Here was the bad news from the database:

<blockquote><code>
$errmsg
</blockquote></code>

This probably shouldn't have happened.
"
     return
}

# database insert went OK



ns_return 200 text/html "[bboard_header "Alert Added"]

<h2>Alert Added</h2>

for $first_names $last_name in the [bboard_complete_backlink $topic_id $topic $presentation_type]

<hr>

<ul>

<li>Topic:  $topic
<li>Address to notify:  $email
<li>Frequency:  $frequency
$keyword_user_report_line

</ul>

Remember that you can disable your alert at any time by returning to 
<a href=\"add-alert.tcl?[export_url_vars topic topic_id]\">
the add alert page</a> and using the \"edit alerts\" feature.

[bboard_footer]
"

