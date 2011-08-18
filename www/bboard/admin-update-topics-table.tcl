# $Id: admin-update-topics-table.tcl,v 3.1 2000/02/19 23:38:04 bdolicki Exp $
set_form_variables_string_trim_DoubleAposQQ
set_form_variables


set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}

if {[bboard_get_topic_info] == -1} {
    return
}

if {[bboard_admin_authorization] == -1} {
    return
}

set selection [ns_db 1row $db "select  u.email as maintainer_email, u.first_names || ' ' || u.last_name as maintainer_name
from bboard_topics t, users u
where topic_id=$topic_id
and t.primary_maintainer_id = u.user_id"]

set_variables_after_query

# cookie checks out; user is authorized

set exception_text ""
set exception_count 0

if { [info exists maintainer_name] && $maintainer_name == "" } {
    append exception_text "<li>You can't have a blank Maintainer Name.  The system uses this information to generate part of the user interface"
    incr exception_count
}

if { [info exists maintainer_email] && $maintainer_email == "" } {
    append exception_text "<li>You can't have a blank Maintainer Email address.  The system uses this information to generate part of the user interface"
    incr exception_count
}

if { $exception_count> 0 } {
    if { $exception_count == 1 } {
	set problem_string "a problem"
	set please_correct "it"
    } else {
	set problem_string "some problems"
	set please_correct "them"
    }
    ns_return 200 text/html "<html>
<head>
<title>Problem Updating Topic</title>
</head>
<body bgcolor=[ad_parameter bgcolor "" "white"] text=[ad_parameter textcolor "" "black"]>
<h2>Problem Updating Topic</h2>

<hr>

We had $problem_string updating your topic:

<ul> 

$exception_text

</ul>

Please back up using your browser, correct $please_correct, 
and resubmit your form.

<p>

Thank you.

[bboard_footer]
"

return 0

}

# we have to treat the textarea stuff specially (some browsers give us a blank line or two)

#if { [info exists policy_statement] && ![regexp {[A-Za-z]} $policy_statement] } {
#    # we have the form variable but there are no alpha characters in it
#    ns_set update [ns_conn form] policy_statement ""
#}

#if { [info exists pre_post_caveat] && ![regexp {[A-Za-z]} $pre_post_caveat] } {
    # we have the form variable but there are no alpha characters in it
#    ns_set update [ns_conn form] pre_post_caveat ""
#}


set sql [util_prepare_update $db bboard_topics "topic_id" $topic_id [ns_conn form]]


if [catch {ns_db dml $db $sql} errmsg] {
    ns_return 200 text/html "<html>
<head>
<title>Topic Not Updated</title>
</head>

<body bgcolor=[ad_parameter bgcolor "" "white"] text=[ad_parameter textcolor "" "black"]>
<h2>Topic Not Updated</h2>

<hr>

The database rejected the update of discussion topic \"$topic\".  Here was
the error message:

<pre>
$errmsg
</pre>

[bboard_footer]"
return 0 

}

# the database insert went OK

set selection [ns_db 1row $db "select unique * from bboard_topics where topic_id=$topic_id"]
set_variables_after_query

ns_return 200 text/html "<html>
<head>
<title>Topic Updated</title>
</head>

<body bgcolor=[ad_parameter bgcolor "" "white"] text=[ad_parameter textcolor "" "black"]>
<h2>Topic Updated</h2>

\"$topic\" updated in 
<a href=\"index.tcl\">[bboard_system_name]</a>

<hr>

If you've read <a href=\"http://photo.net/wtr/dead-trees/\">Philip
Greenspun's book on Web publishing</a> then you'll appreciate the SQL:

<blockquote><pre>
$sql
</pre></blockquote>

<p>

Remember to link to <a href=\"q-and-a.tcl?[export_url_vars topic topic_id]\">the user Q&A page</a> from your public pages and bookmark
<a href=\"admin-home.tcl?[export_url_vars topic topic_id]\">the
admin page</a> after you return there.

[bboard_footer]"
