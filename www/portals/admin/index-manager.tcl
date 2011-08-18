#
# /portals/admin/index-manager.tcl
#
# Shows managers of serveral portals a list of their options
#
# by aure@arsdigita.com and dh@arsdigita.com
#
# Last modified: 10/8/1999
#
# $Id: index-manager.tcl,v 3.2.2.1 2000/04/28 15:11:17 carsten Exp $
#

set db [ns_db gethandle]
set user_id [ad_verify_and_get_user_id]

# get all the group_ids where this user_id is an administrator of a portal group

set group_list_sql "select  distinct group_id, group_name"

set group_list_clause "
    from    user_groups 
    where   ad_user_has_role_p ( $user_id, group_id, 'administrator' ) = 't'
    and     group_type = 'portal_group'
    order by  group_name"

set number_of_groups [database_to_tcl_string $db "select count(*) $group_list_clause"]

# if not an administrator then bounce to the regular index.tcl
if {$number_of_groups ==0 } {
    ad_returnredirect [ad_parameter MainPublicURL portals]
    return
}

# if only administrator of one portal, set the group_id and redirect to the administration page
if {$number_of_groups==1} {
    set group_id [database_to_tcl_string $db "select user_groups.group_id $group_list_clause"]
    ad_returnredirect manage-portal?[export_url_vars group_id]
    return
}

# if user_id is administrator of many groups - let the person choose the page to admin
if {$number_of_groups > 1 } {
    set output_html "Choose the group which you want to manage:<br>"
    set selection [ns_db select $db "$group_list_sql $group_list_clause"]
    set group_list ""
    while { [ns_db getrow $db $selection] } {
	set_variables_after_query
	append group_list "<li> <a href=manage-portal?[export_url_vars group_id ]>$group_name</a>"
    }
} 

# done with the database
ns_db releasehandle $db

# ------------------------------------------------
# serve the page

# Get generic display information
portal_display_info

set page_content "
[portal_admin_header "[ad_parameter SystemName portals] Management"]
<hr>

You are manager of more than one portal group, please choose one:
<ul>
$group_list
</ul>
[portal_admin_footer]"

ns_return 200 text/html $page_content










