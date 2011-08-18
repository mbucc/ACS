# $Id: admin-bozo-pattern.tcl,v 3.0 2000/02/06 03:32:34 ron Exp $
set_the_usual_form_variables
# topic_id, topic, the_regexp 

set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}

 
if  {[bboard_get_topic_info] == -1} {
    return}

if {[bboard_admin_authorization] == -1} {
	return}


# cookie checks out; user is authorized

if [catch {set selection [ns_db 0or1row $db "select bt.*,u.email as maintainer_email, u.first_names || ' ' || u.last_name as maintainer_name, presentation_type
 from bboard_topics bt, users u
 where bt.topic_id=$topic_id
 and bt.primary_maintainer_id = u.user_id"]} errmsg] {
    [bboard_return_cannot_find_topic_page]
    return
}
# we found the data we needed
set_variables_after_query

set selection [ns_db 1row $db "select bbp.*, first_names, last_name
from bboard_bozo_patterns bbp, users
where bbp.creation_user = users.user_id
and topic_id = $topic_id
and the_regexp = '$QQthe_regexp'"]
set_variables_after_query

ReturnHeaders

ns_write "<html>
<head>
<title>Bozo Pattern in $topic:  $the_regexp</title>
</head>
<body bgcolor=[ad_parameter bgcolor "" "white"] text=[ad_parameter textcolor "" "black"]>

<h2>$the_regexp</h2>

a bozo pattern
for <a href=\"admin-home.tcl?[export_url_vars topic]\">$topic</a>

<hr>

<ul>
<li>Regular Expression:  \"$the_regexp\"
<li>Where we look:  $scope
<li>What we say to users who run afoul of this regexp:
<blockquote>
$message_to_user
</blockquote>
<li>Why this was created:
<blockquote>
$creation_comment
<br>
<br>
-- <a href=\"/shared/community-member.tcl?user_id=$creation_user\">$first_names $last_name</a>, [util_AnsiDatetoPrettyDate $creation_date]
</blockquote>

</ul>

If you don't like this bozo pattern, you can 

<ul>
<li><a href=\"admin-bozo-pattern-delete.tcl?[export_url_vars topic topic_id the_regexp]\">delete it</a>

<p>

<li><a href=\"admin-bozo-pattern-edit.tcl?[export_url_vars topic topic_id the_regexp]\">edit it</a>

</ul>


[bboard_footer]
"
