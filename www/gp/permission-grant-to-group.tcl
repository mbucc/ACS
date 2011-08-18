#
# /gp/permission-grant-to-group.tcl
#
# created by michael@arsdigita.com, 2000-02-27
#
# $Revision: 3.2 $
# $Date: 2000/03/02 08:20:24 $
# $Author: michael $
#

ad_page_variables {
    on_what_id
    on_which_table
    object_name
    return_url
}

set user_id [ad_verify_and_get_user_id]

set db [ns_db gethandle]

ad_require_permission $db $user_id "administer" $on_what_id $on_which_table

set scope "group"

# Fetch all public and approved groups that do not have permission
# on this database row.
#
set query "select g.group_id, g.group_name || ' (' || gt.pretty_name || ')'
from user_groups g, user_group_types gt
where not exists (select 1
                  from general_permissions p
                  where p.scope = 'group'
                  and p.group_id = g.group_id)
and g.active_p = 't'
and g.existence_public_p = 't'
and g.approved_p = 't'
and g.group_type = gt.group_type
order by g.group_type, g.group_name"

set user_group_widget "<select name=group_id>
[db_html_select_value_options $db $query]
</select>"

ns_db releasehandle $db

ad_return_template
