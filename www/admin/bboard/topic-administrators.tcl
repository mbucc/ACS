# /www/admin/bboard/topic-administrators.tcl
ad_page_contract {
    Displays the administrators for one bboard topic
    
    @param topic the name of the bboard topic
    @param topic_id the ID of the bboard topic

    @cvs-id topic-administrators.tcl,v 3.3.2.5 2000/09/22 01:34:22 kevin Exp
} {
    topic:notnull
    topic_id:integer,notnull
}

# -----------------------------------------------------------------------------

append page_content "
[ad_admin_header "[ad_system_name] $topic administrators"]

<h2>Administrators for $topic</h2>

[ad_admin_context_bar [list "index.tcl" "BBoard Hyper-Administration"] \
	[list "administer.tcl?[export_url_vars topic]" "One Bboard"] \
	Administrators]

<hr>
"


db_1row primary_maintainer_info "
select users.user_id, first_names, last_name from
bboard_topics, users
where bboard_topics.primary_maintainer_id = users.user_id
and topic = :topic"

append page_content "
<p>
The primary maintainer is <A href=\"/admin/users/one?user_id=$user_id\">$first_names $last_name.</a>
<p>
Other maintainers.
<ul>"

set admin_group_id [ad_administration_group_id "bboard" $topic_id]

if { [empty_string_p $admin_group_id] } {
    ad_return_error "Missing Admin Group" "Missing administration group for this bboard topic."
    return
}

db_foreach maintainers "
select distinct u.user_id, u.first_names, u.last_name
from users u, user_group_map ugm
where ugm.user_id = u.user_id
and ugm.group_id = :admin_group_id
order by u.last_name asc" {

    append page_content "<li><a href=\"/admin/users/one?user_id=$user_id\">$first_names $last_name</a>-<a href=\"administrator-delete?[export_url_vars topic topic_id admin_group_id user_id]\">Remove</a>"
}

append page_content "
</ul>
<h3>Add Administrator</h3>
<form action=\"/user-search\" method=post>
[export_form_vars topic topic_id]
<input type=hidden name=target value=\"/admin/bboard/administrator-add.tcl\">
<input type=hidden name=passthrough value=\"topic topic_id\">
<input type=hidden name=custom_title value=\"Choose a Member to Administrate $topic\">
Search for a user to add to the administration list.<br>
<table border=0>
<tr><td>Email address:<td><input type=text name=email size=40></tr>
<tr><td colspan=2>or by</tr>
<tr><td>Last name:<td><input type=text name=last_name size=40></tr>
</table>
<p>
<center>
<input type=submit name=submit value=\"Find Administrator\">
</center>
</form>
[ad_admin_footer]
"
 

doc_return  200 text/html $page_content
