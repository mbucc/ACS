# /gp/permission-grant-to-group.tcl
#

ad_page_contract {
    @author michael@arsdigita.com
    @creation-date 2000-02-27
    @cvs-id permission-grant-to-group.tcl,v 3.5.2.7 2000/08/09 23:31:10 kevin Exp
} {
    on_what_id:integer,notnull
    on_which_table:notnull
    object_name:notnull
    return_url:notnull
}


set user_id [ad_verify_and_get_user_id]


ad_require_permission $user_id "administer" $on_what_id $on_which_table

# set scope "group"

# Fetch all public and approved groups that do not have permission
# on this database row.
#
set query "select g.group_id, 
g.group_name || ' (' || gt.pretty_name || ')', 
ad_group_member_p(:user_id, g.group_id) member_p,  
g.parent_group_id,  
user_group_name_from_id(g.parent_group_id) parent_group_name
from user_groups g, user_group_types gt
where g.active_p = 't'
and g.existence_public_p = 't'
and g.approved_p = 't'
and g.group_type = gt.group_type
order by member_p desc, g.group_type, parent_group_name, g.group_name"

set options [db_list_of_lists gp_groupinfo_get $query]
db_release_unused_handles

set user_group_widget "<select name=group_id size=15>\n"
set current_parent_group_id ""

# display subgroups beneath their parent group
foreach option $options {
    if { $current_parent_group_id != [lindex $option 3] } {
	set current_parent_group_id [lindex $option 3]
	if { $current_parent_group_id != "" } {
	    append user_group_widget "<option value=\"[philg_quote_double_quotes [lindex $option 3]]\">[lindex $option 4]\n"
	}
    }
    if { $current_parent_group_id != "" } {
	set name "&nbsp;&nbsp;&nbsp;&nbsp;[lindex $option 1]"
    } else {
	set name "[lindex $option 1]"
    }
	
    append user_group_widget "<option value=\"[philg_quote_double_quotes [lindex $option 0]]\">$name\n"
}

append user_group_widget "</select>\n"

ad_return_template








