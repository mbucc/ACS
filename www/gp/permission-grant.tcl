# /gp/permission-grant.tcl

ad_page_contract {
    This script performs the actual insertion of rows into the
    general_permissions table. It is used to add user permissions,
    role permissions, group permissions, and public permissions
    (both for only registered users and all users).

    @author michael@arsdigita.com
    @creation-date 2000-02-27
    @cvs-id permission-grant.tcl,v 3.9.6.7 2000/07/26 18:22:04 jwong Exp
} {
    on_what_id:integer,notnull
    on_which_table:notnull
    scope:notnull
    { user_id_from_search:naturalnum,optional "" }
    { group_id:integer,optional "" }
    { role:optional "" }
    permission_types:multiple,optional
    return_url:notnull
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


ad_require_permission $user_id "administer" $on_what_id $on_which_table

switch $scope {
    user {
	set user_id_criterion "user_id = :user_id_from_search"

	set group_id "[db_null]"
	set group_id_criterion "group_id is NULL"
	set role "[db_null]"
	set role_criterion "role is NULL"
    }

    group_role {
	set group_id_criterion "group_id = :group_id"
	###set role "'$role'"
	set role_criterion "role = :role"

	set user_id_from_search "[db_null]"
	set user_id_criterion "user_id is NULL"
    }

    group {
	set group_id_criterion "group_id = :group_id"

	set user_id_from_search "[db_null]"
	set user_id_criterion "user_id is NULL"
	set role "[db_null]"
	set role_criterion "role is NULL"
    }

    registered_users -
    all_users {
	set user_id_from_search [db_null]
	set user_id_criterion "user_id is NULL"
	set group_id [db_null]
	set group_id_criterion "group_id is NULL"
	set role [db_null]
	set role_criterion "role is NULL"
    }
}

db_transaction {

# Insert a row for each type of permission being granted, making sure
# not to duplicate existing permissions.
#
foreach permission_type $permission_types {

    db_dml gp_permission_insert "insert into general_permissions
    (permission_id, on_what_id, on_which_table,
    scope, user_id, group_id, role,
    permission_type)
    select
    gp_id_sequence.nextval, :on_what_id, :on_which_table,
    :scope, :user_id_from_search, :group_id, :role,
    :permission_type
    from dual
    where not exists (select 1
                  from general_permissions
                  where on_what_id = :on_what_id
                  and on_which_table = lower(:on_which_table)
                  and scope = :scope
                  and $user_id_criterion
                  and $group_id_criterion
                  and $role_criterion
                  and permission_type = lower(:permission_type))"
}

} on_error {

    db_release_unused_handles
    ad_return_error "Error" "DML failed."
}

db_release_unused_handles

ad_returnredirect $return_url
