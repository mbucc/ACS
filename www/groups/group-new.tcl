# $Id: group-new.tcl,v 3.0.4.1 2000/04/28 15:10:56 carsten Exp $
# File: /groups/group-new.tcl
# Date: mid-1998
# Contact: teadams@mit.edu, tarik@mit.edu
# Purpose: creation of a new user group
# 
# Note: groups_public_dir, group_type_url_p, group_type, group_type_pretty_name, 
#       group_type_pretty_plural, group_public_root_url and group_admin_root_url
#       are set in this environment by ug_serve_group_pages. if group_type_url_p
#       is 0, then group_type, group_type_pretty_name and group_type_pretty_plural
#       are empty strings)

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set user_id [ad_get_user_id]

if {$user_id == 0} {
   ad_returnredirect "/register.tcl?return_url=[ad_urlencode "[ug_url]/group-new.tcl"]"
    return
}

ReturnHeaders

ns_write "[ad_header "Define a New User Group"]

<h2>Define a New User Group</h2>

in <a href=/>[ad_system_name]</a>

<hr>

Which of these categories best characterizes your group?

<ul>

"

set db [ns_db gethandle]

set selection [ns_db select $db "select * 
from user_group_types
where approval_policy <> 'closed'"]

set count 0
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    incr count
    ns_write "<li><a href=\"group-new-2.tcl?[export_url_vars group_type]\">$pretty_name</a>\n"
}

if { $count == 0 } {
    ns_write "currently there are no types of groups that users may define"
}

ns_write "

<p>

<li>if none of the preceding categories fit the group you want to
create <a href=\"mailto:[ad_system_owner]\">send mail to
[ad_system_owner]</a> and ask for a new type of group to be created.

</ul>

[ad_footer]
"

