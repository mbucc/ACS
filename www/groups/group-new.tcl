# /www/groups/group-new.tcl

ad_page_contract {
    @cvs-id group-new.tcl,v 3.2.6.8 2001/01/10 21:21:41 khy Exp

 Purpose: creation of a new user group
 
 Note: groups_public_dir, group_type_url_p, group_type, group_type_pretty_name, 
       group_type_pretty_plural, group_public_root_url and group_admin_root_url
       are set in this environment by ug_serve_group_pages. if group_type_url_p
       is 0, then group_type, group_type_pretty_name and group_type_pretty_plural
       are empty strings)
} {
}
if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set user_id [ad_get_user_id]

if {$user_id == 0} {
   ad_returnredirect "/register.tcl?return_url=[ad_urlencode "[ug_url]/group-new.tcl"]"
    return
}



set page_html "[ad_header "Define a New User Group"]

<h2>Define a New User Group</h2>

in <a href=/>[ad_system_name]</a>

<hr>

Which of these categories best characterizes your group?

<ul>

"



db_foreach get_ugt_info "select group_type, pretty_name
from user_group_types
where approval_policy <> 'closed'" {


    append page_html "<li><a href=\"group-new-2?[export_url_vars group_type]\">$pretty_name</a>\n"
} if_no_rows {


    append page_html "currently there are no types of groups that users may define"
}

append page_html "

<p>

<li>if none of the preceding categories fit the group you want to
create <a href=\"mailto:[ad_system_owner]\">send mail to
[ad_system_owner]</a> and ask for a new type of group to be created.

</ul>

[ad_footer]
"
doc_return  200 text/html $page_html




