# $Id: group-type-all-members.tcl,v 3.0.4.1 2000/04/28 15:09:32 carsten Exp $
set_the_usual_form_variables

# group_type

set user_id [ad_get_user_id]
if {$user_id == 0} {
   ad_returnredirect /register.tcl?return_url=[ns_urlencode "/admin/ug/group.tcl?[export_url_vars group_type]"]
    return
}




set db [ns_db gethandle]

set selection [ns_db 1row $db "select * from user_group_types where group_type = '$QQgroup_type'"]

set_variables_after_query

ReturnHeaders 

ns_write "[ad_admin_header "$pretty_name"]

<h2>$pretty_name</h2>

one of <a href=\"index.tcl\">the group types</a> in 
<a href=\"/admin\">[ad_system_name] administration</a> 

<hr>

<ul>
"

# Note that here the only reason we grab parent_name is to order by it
# to force children beneath their parent while keeping the top nodes alphabetical
set selection [ns_db select $db \
	"select ug.group_id, ug.group_name, ug.registration_date, ug.approved_p, 
                user_groups_number_members(ug.group_id) as n_members, level,
                user_group_name_from_id(ug.parent_group_id) as parent_name
           from user_groups ug
          where group_type = '$QQgroup_type'
     connect by prior group_id=parent_group_id
     start with parent_group_id is null
       order by lower(parent_name) || lower(group_name)"]

set html ""
set current_level 1
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    if { $level > $current_level } {
	append html "  <ul>\n"
	incr current_level
    } elseif { $level < $current_level } {
	append html "  </ul>\n"
	set current_level [expr $current_level - 1]
    }	
    append html "<li><a href=\"group.tcl?group_id=$group_id\">$group_name</a> ($n_members [util_decode $n_members 1 member members])"
    if { $approved_p == "f" } {
	append html " <font color=red>not approved</font>"
    }
    append html "\n"
}
if { [exists_and_not_null level] && $level <= $current_level } {
    append html "  </ul>\n"
}	
if { [empty_string_p $html] } {
    set html "  <li><i>None</i>\n"
}

ns_db releasehandle $db

ns_write "
$html
</ul>
[ad_admin_footer]
"