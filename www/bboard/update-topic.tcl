# $Id: update-topic.tcl,v 3.0 2000/02/06 03:34:51 ron Exp $
set_form_variables_string_trim_DoubleAposQQ
set_form_variables

set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}


set exception_text ""
set exception_count 0

if { ![info exists maintainer_name] || $maintainer_name == "" } {
    append exception_text "<li>You must enter a Maintainer Name.  The system uses this information to generate part of the user interface"
    incr exception_count
}

if { ![info exists maintainer_email] || $maintainer_email == "" } {
    append exception_text "<li>You must enter a Maintainer Email address.  The system uses this information to generate part of the user interface"
    incr exception_count
}

if { ![info exists admin_password] || $admin_password == "" } {
    append exception_text "<li>You must enter an administration password.  Otherwise any random person from the Internet would be able to delete all of the messages on the bboard, restrict it so that users couldn't get into the bboard, etc."
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

<hr>

<a href=\"mailto:[bboard_system_owner]\"><address>[bboard_system_owner]</address></a>

</BODY>
</HTML>
"

return 0

}

# no exceptions found

set extra_set ""

if { [bboard_use_ns_perm_authorization_p] == 1 && [info exists ns_perm_group] } {
    if { $ns_perm_group == {Do Not Use ns_perm} } {
	set extra_set ",\nns_perm_group = NULL"
    } else {
	set extra_set ",\nns_perm_group = '$QQns_perm_group'"
    }
}

if [catch {ns_db dml $db "update bboard_topics
set backlink = '$QQbacklink',
backlink_title = '$QQbacklink_title',
admin_password = '$QQadmin_password',
user_password = '$QQuser_password',
maintainer_name = '$QQmaintainer_name',
maintainer_email = '$QQmaintainer_email',
subject_line_suffix = '$QQsubject_line_suffix',
pre_post_caveat = '$QQpre_post_caveat',
notify_of_new_postings_p = '$QQnotify_of_new_postings_p',
presentation_type = '$QQpresentation_type' $extra_set
where topic_id = $topic_id"} errmsg] {
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

<hr>
<a href=\"mailto:[bboard_system_owner]\"><address>[bboard_system_owner]</address></a>

</body>
</html>"
return 0 

}

# the database insert went OK

set selection [ns_db 1row $db "select unique * from bboard_topics where topic_id = $topic_id"]
set_variables_after_query

if { $notify_of_new_postings_p == "t" } {
    set notify_blurb "Maintainer will be notified via email every time there is a new posting"
} else {
    set notify_blurb "Maintainer will not be notified of new postings"
}

if { [bboard_use_ns_perm_authorization_p] == 1 && $user_password != "" } {
    if { $ns_perm_group != "" } {
    set authorization_line "<li>this is a private group, open only to those who know the user password and members of the \"$ns_perm_group\" ns_perm group"
    } else {
	# private but not using ns_perm
	set authorization_line "<li>this is a private group, open only to those who know the user password"
    }
} else {
    set authorization_line ""
}

ns_return 200 text/html "<html>
<head>
<title>Topic Updated</title>
</head>

<body bgcolor=[ad_parameter bgcolor "" "white"] text=[ad_parameter textcolor "" "black"]>
<h2>Topic Updated</h2>

\"$topic\" updated in 
<a href=\"index.tcl\">[bboard_system_name]</a>

<hr>

<ul>
<li>Backlink:  <a href=\"$backlink\">$backlink_title</a>
<li>Maintainer:  $maintainer_name ($maintainer_email)
<li>Admin Password:  \"$admin_password\"
<li>User Password:  \"$user_password\"
$authorization_line
<li>What to add after the Subject line:  \"$subject_line_suffix\"
<li>$notify_blurb
</ul>




Remember to link to <a href=\"main-frame.tcl?[export_url_vars topic topic_id]\">the user page</a> from your public pages and bookmark
<a href=\"admin-home.tcl?[export_url_vars topic topic_id]\">the
admin page</a> after you return there.

[bboard_footer]"
