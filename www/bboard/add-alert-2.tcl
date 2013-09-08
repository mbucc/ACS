# /www/bboard/add-alert-2.tcl
ad_page_contract {
    Process a new bboard alert request

    @param topic_id the topic id of the topic
    @param topic the name of the topic to add a user alert for
    @param frequency something here
    @param keywords something else here

    @cvs-id add-alert-2.tcl,v 3.2.2.5 2000/09/22 01:36:40 kevin Exp
} {
    topic_id:integer,notnull
    topic:notnull
    frequency:notnull
    keywords
}

# -----------------------------------------------------------------------------

if { [bboard_get_topic_info] == -1 } {
    return
}

ad_get_user_info

set extra_columns ""
set extra_values ""
set keyword_user_report_line ""

if { [info exists keywords] && $keywords != "" } {
    # we have a keyword-limited search
    set extra_columns ", keywords"
    set extra_values ", :keywords"
    set keyword_user_report_line "<li>Keywords:  \"$keywords\""
}

if [catch {db_dml insert_new_user_bboard_alert "
insert into bboard_email_alerts ( user_id, topic_id, frequency $extra_columns )
values
( :user_id, :topic_id, :frequency $extra_values )"} errmsg] {
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


doc_return  200 text/html "[bboard_header "Alert Added"]

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
<a href=\"add-alert?[export_url_vars topic topic_id]\">
the add alert page</a> and using the \"edit alerts\" feature.

[bboard_footer]
"

