# $Id: policy.tcl,v 3.0 2000/02/06 03:34:03 ron Exp $
set_form_variables_string_trim_DoubleAposQQ
set_form_variables

# topic required

set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}
 
if  {[bboard_get_topic_info] == -1} {
    return}





ns_return 200 text/html "[bboard_header "About the $topic Forum"]

<h2>About the $topic Forum</h2>

[ad_context_bar_ws_or_index [list "index.tcl" [bboard_system_name]] [list [bboard_raw_backlink $topic_id $topic $presentation_type 0] $topic] "Policy"]


<hr>

$policy_statement

<h3>How this System Works</h3>

This bboard software was written by 
<a href=\"http://photo.net/philg/\">Philip Greenspun</a> 
and the design choices are described in 
<a href=\"http://photo.net/wtr/thebook/\">his real dead trees book on Web publishing</a>.  The intent is to combine the best of both the Web and the email worlds.

<P>

We use the Web to collect a permanent categorized and indexed record
of the discussion.  We use email to notify people when someone has
posted a response to a question.  We use email also to send instant
notifications or periodic summaries of forum activity (you can <a
href=\"add-alert.tcl?[export_url_vars topic topic_id]\">request
to be notified</a> if you'd like to follow the forum via email).

[bboard_footer]
"
