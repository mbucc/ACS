#
# /gp/permission-grant.tcl
#
# This script performs the actual insertion of rows into the
# general_permissions table. It is used to add user permissions,
# role permissions, group permissions, and public permissions
# (both for only registered users and all users).
#
# created by michael@arsdigita.com, 2000-02-27
#
# $Revision: 3.8.2.1 $
# $Date: 2000/04/28 15:10:55 $
# $Author: carsten $
#

ad_page_variables {
    on_what_id
    on_which_table
    scope
    {user_id_from_search ""}
    {group_id ""}
    {role ""}
    {permission_types -multiple-list}
    return_url
}

page_validation {
    if { [llength $permission_types] == 0 } {
	error "You selected no permission types."
    }

    switch $scope {
	user {
	    if { [empty_string_p $user_id_from_search] } {
		error "missing user_id"
	    }
	}

	group_role {
	    if { [empty_string_p $group_id] } {
		error "missing group_id"
	    }

	    if { [empty_string_p $role] } {
		error "missing role"
	    }
	}

	group {
	    if { [empty_string_p $group_id] } {
		error "missing group_id"
	    }
	}

	registered_users -
	all_users {
	}

	default {
	    error "unknown scope: $scope"
	}
    }
}

set user_id [ad_verify_and_get_user_id]

set db [ns_db gethandle]

ad_require_permission $db $user_id "administer" $on_what_id $on_which_table

switch $scope {
    user {
	set user_id_criterion "user_id = $user_id_from_search"

	set group_id "null"
	set group_id_criterion "group_id is null"
	set role "null"
	set role_criterion "role is null"
    }

    group_role {
	set group_id_criterion "group_id = $group_id"
	set role "'$role'"
	set role_criterion "role = $role"

	set user_id_from_search "null"
	set user_id_criterion "user_id is null"
    }

    group {
	set group_id_criterion "group_id = $group_id"

	set user_id_from_search "null"
	set user_id_criterion "user_id is null"
	set role "null"
	set role_criterion "role is null"
    }

    registered_users -
    all_users {
	set user_id_from_search "null"
	set user_id_criterion "user_id is null"
	set group_id "null"
	set group_id_criterion "group_id is null"
	set role "null"
	set role_criterion "role is null"
    }
}

ns_db dml $db "begin transaction"

# Insert a row for each type of permission being granted, making sure
# not to duplicate existing permissions.
#
foreach permission_type $permission_types {

    ns_db dml $db "insert into general_permissions
 (permission_id, on_what_id, on_which_table,
  scope, user_id, group_id, role,
  permission_type)
select
 gp_id_sequence.nextval, '$on_what_id', '$on_which_table',
 '$scope', $user_id_from_search, $group_id, $role,
 '$permission_type'
from dual
where not exists (select 1
                  from general_permissions
                  where on_what_id = '$on_what_id'
                  and on_which_table = lower('$on_which_table')
                  and scope = '$scope'
                  and $user_id_criterion
                  and $group_id_criterion
                  and $role_criterion
                  and permission_type = lower('$permission_type'))"
}

ns_db dml $db "end transaction"

ad_returnredirect $return_url
