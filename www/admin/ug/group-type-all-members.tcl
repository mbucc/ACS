ad_page_contract {
    List all the groups in a group type

    @param group_type The type of group to list from

    @cvs-id  group-type-all-members.tcl,v 3.3.2.7 2000/09/22 01:36:13 kevin Exp
} {
    group_type:notnull
}

# upgrade to 3.4 by teadams@arsdigita.com on July 9, 2000

set user_id [ad_get_user_id]
ad_maybe_redirect_for_registration

set pretty_name [db_string group_type_pretty_name "select pretty_name from user_group_types where group_type = :group_type"]

append html "[ad_admin_header "$pretty_name"]

<h2>$pretty_name</h2>

one of <a href=\"index\">the group types</a> in 
<a href=\"/admin\">[ad_system_name] administration</a> 

<hr>

<ul>
"


set current_level 1

# Note that here the only reason we grab parent_name is to order by it
# to force children beneath their parent while keeping the top nodes alphabetical
db_foreach user_groups_in_group_type "select ug.group_id, ug.group_name, ug.registration_date, ug.approved_p, 
                user_groups_number_members(ug.group_id) as n_members, level,
                user_group_name_from_id(ug.parent_group_id) as parent_name
           from user_groups ug
          where group_type = :group_type
     connect by prior group_id=parent_group_id
     start with parent_group_id is null
       order by lower(parent_name) || lower(group_name)" {

    if { $level > $current_level } {
	append html "  <ul>\n"
	incr current_level
    } elseif { $level < $current_level } {
	append html "  </ul>\n"
	set current_level [expr $current_level - 1]
    }	
    append html "<li><a href=\"group?group_id=$group_id\">$group_name</a> ($n_members [util_decode $n_members 1 member members])"
    if { $approved_p == "f" } {
	append html " <font color=red>not approved</font>"
    }
    append html "\n"
} if_no_rows {
    append html "  <li><i>None</i>\n"
}
if { [exists_and_not_null level] && $level <= $current_level } {
    append html "  </ul>\n"
} 

doc_return  200 text/html  "
$html
</ul>
[ad_admin_footer]
"




