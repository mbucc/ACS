#
# /www/gp/administer-permissions.tcl
#
# UI for editing the permissions for a specific database row
#
# created by michael@arsdigita.com, 2000-02-25
#
# $Id: administer-permissions.tcl,v 1.1.2.4 2000/03/24 01:57:47 michael Exp $
#

# Given that a row in the database typically represents an
# object (e.g., a web page, a person), this page accepts
# an object_name parameter which we use to build a meaningful
# page title.
#
ad_page_variables {
    on_what_id
    on_which_table
    {object_name "Row $on_what_id of Table $on_which_table"}
    return_url
}

set user_id [ad_verify_and_get_user_id]

set db [ns_db gethandle]

ad_require_permission $db $user_id "administer" \
	$on_what_id $on_which_table $return_url

# Fetch the permission grid for this database row and format it into
# a pretty HTML table. Should be easy to turn it into XML later.
#
set permission_grid "<table cellpadding=3>
<tr><th>Scope</th><th>Read?</th><th>Comment?</th><th>Write?</th><th>Administer?</th></tr>
"

# We need to export the current page as return_url for links that
# we create below, so we save the return_url value obtained from
# the form input in a separate variabel and then restore it later.
#
set return_url_save $return_url
set return_url "[ns_conn url]?[ns_conn query]"

# Initialize the CSS class for table rows.
#
set row_class "odd"

set registered_users_scope_pretty_name "Registered Users Only"
set all_users_scope_pretty_name "All Users"

# This query fetches all of the standard permission grants (i.e.,
# read, comment, write, and administer) for the specified database
# row. Also, it appends rows for the 'registered_users' and
# 'all_users' scopes if no permissions have been granted to those
# scopes (this is what the two queries UNIONed onto the end do).
#
set selection [ns_db select $db "select
 decode(pg.scope,
  'user',
   '<a href=\"/shared/community-member.tcl?user_id=' || u.user_id ||
   '\">' || u.first_names || ' ' || u.last_name || '</a>',
  'group_role', g.group_name || ' ' || pg.role,
  'group', g.group_name,
  'registered_users', '$registered_users_scope_pretty_name',
  'all_users', '$all_users_scope_pretty_name') as permission_owner,
 pg.scope as scope, pg.user_id, pg.group_id, pg.role,
 pg.read_permission_p,
 pg.comment_permission_p,
 pg.write_permission_p,
 pg.administer_permission_p,
 decode(scope, 'user', 1, 'group_role', 2, 'group', 3,
        'registered_users', 4, 'all_users', 5) as display_order
from general_permissions_grid pg, users u, user_groups g
where pg.on_what_id = $on_what_id
and pg.on_which_table = lower('$on_which_table')
and pg.user_id = u.user_id (+)
and pg.group_id = g.group_id (+)
union
select
 '$registered_users_scope_pretty_name' as permission_owner,
 'registered_users' as scope,
 to_number(null) as user_id,
 to_number(null) as group_id,
 to_char(null) as role,
 'f' as read_permission_p,
 'f' as comment_permission_p,
 'f' as write_permission_p,
 'f' as administer_permission_p,
 4 as display_order
from dual
where not exists (select 1
                  from general_permissions_grid
                  where on_what_id = $on_what_id
                  and on_which_table = lower('$on_which_table')
                  and scope = 'registered_users')
union
select
 '$all_users_scope_pretty_name' as permission_owner,
 'all_users' as scope,
 to_number(null) as user_id,
 to_number(null) as group_id,
 to_char(null) as role,
 'f' as read_permission_p,
 'f' as comment_permission_p,
 'f' as write_permission_p,
 'f' as administer_permission_p,
 5 as display_order
from dual
where not exists (select 1
                  from general_permissions_grid
                  where on_what_id = $on_what_id
                  and on_which_table = lower('$on_which_table')
                  and scope = 'all_users')
order by display_order asc"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query

    append permission_grid "<tr class=$row_class><td>$permission_owner</td>"

    foreach permission_type {read comment write administer} {
	# Read the value of "<permission_type>_permission_p" into a
	# generically-named variable.
	#
	set permission_p [set "${permission_type}_permission_p"]

	set toggle_url "permission-toggle?[export_url_vars on_what_id on_which_table object_name permission_type scope user_id group_id role return_url]"

	append permission_grid "<td align=center>[util_PrettyBoolean $permission_p] (<a href=\"$toggle_url\">[ad_decode $permission_p "t" "revoke" "grant"]</a>)</td>"

    }

    append permission_grid "</tr>\n"

    set row_class [ad_decode $row_class "odd" "even" "odd"]
}

append permission_grid "</table>"

set grant_permission_to_user_link "<a href=\"permission-grant-to-user?[export_url_vars on_what_id on_which_table object_name return_url]\">Grant permission to a user</a>"

set grant_permission_to_group_link "<a href=\"permission-grant-to-group?[export_url_vars on_what_id on_which_table object_name return_url]\">Grant permission to a user group</a>"

# Restore the value of return_url to that obtained from the form
# input.
#
set return_url $return_url_save

ns_db releasehandle $db

ad_return_template
