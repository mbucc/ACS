#
# /www/gp/permission-toggle.tcl
#
# created by michael@arsdigita.com, 2000-02-25
#
# Given form input that identifies a specific permission,
# deletes the permission if it already exists or inserts
# it if it does not.
#
# $Id: permission-toggle.tcl,v 3.5.2.2 2000/04/28 15:10:56 carsten Exp $
#

ad_page_variables {
    on_what_id
    on_which_table
    object_name
    scope
    {user_id ""}
    {group_id ""}
    {role ""}
    permission_type 
    return_url
}

page_validation {
    switch $scope {
	user {
	    if { [empty_string_p $user_id] } {
		error "\"user_id\" required but not supplied"
	    }
	}

	group_role {
	    if { [empty_string_p $group_id] } {
		error "\"group_id\" required but not supplied"
	    }

	    if { [empty_string_p $role] } {
		error "\"role\" required but not supplied"
	    }
	}

	group {
	    if { [empty_string_p $group_id] } {
		error "\"group_id\" required but not supplied"
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

set local_user_id [ad_verify_and_get_user_id]

set db [ns_db gethandle]

ad_require_permission $db $local_user_id "administer" $on_what_id $on_which_table

# Does the specified permission exist?
#
switch $scope {
    user {
	set permission_id [database_to_tcl_string $db "select
 ad_general_permissions.user_permission_id($user_id, '$permission_type', '$on_what_id', '$on_which_table')
from dual"]
    }

    group_role {
	set permission_id [database_to_tcl_string $db "select
 ad_general_permissions.group_role_permission_id($group_id, '$role', '$permission_type', '$on_what_id', '$on_which_table')
from dual"]
    }

    group {
	set permission_id [database_to_tcl_string $db "select
 ad_general_permissions.group_permission_id($group_id, '$permission_type', '$on_what_id', '$on_which_table')
from dual"]
    }

    registered_users {
	set permission_id [database_to_tcl_string $db "select
 ad_general_permissions.reg_users_permission_id('$permission_type', '$on_what_id', '$on_which_table')
from dual"]
    }

    all_users {
	set permission_id [database_to_tcl_string $db "select
 ad_general_permissions.all_users_permission_id('$permission_type',
  '$on_what_id', '$on_which_table')
from dual"]
    }
}

if { $permission_id != 0 } {
    # If the permission exists, then check to see if it's the last
    # 'administer' permission. If it is, then present a confirmation
    # page. Otherwise, revoke it.
    #
    if {
	$permission_type == "administer"
	&& [ad_permission_count $db $on_what_id $on_which_table \
		$permission_type] == 1
    } {
	ns_db releasehandle $db

	ad_returnredirect "revoke-only-administer-permission?[export_url_vars on_what_id on_which_table object_name permission_id return_url]"
	return

    } else {
	ns_db dml $db "begin
 ad_general_permissions.revoke_permission($permission_id);
end;"
    }

} else {
    # Otherwise, grant the permission.
    #
    switch $scope {
	user {
	    ns_ora exec_plsql $db "begin :1 := ad_general_permissions.grant_permission_to_user($user_id, '$permission_type', '$on_what_id', '$on_which_table'); end;"
	}

	group_role {
	    ns_ora exec_plsql $db "begin :1 := ad_general_permissions.grant_permission_to_role($group_id, '$role', '$permission_type', '$on_what_id', '$on_which_table'); end;"
	}

	group {
	    ns_ora exec_plsql $db "begin :1 := ad_general_permissions.grant_permission_to_group($group_id, '$permission_type', '$on_what_id', '$on_which_table'); end;"
	}

	registered_users {
	    ns_ora exec_plsql $db "begin :1 := ad_general_permissions.grant_permission_to_reg_users('$permission_type', '$on_what_id', '$on_which_table'); end;"
	}

	all_users {
	    ns_ora exec_plsql $db "begin :1 := ad_general_permissions.grant_permission_to_all_users('$permission_type', '$on_what_id', '$on_which_table'); end;"
	}
    }
}

ad_returnredirect $return_url
