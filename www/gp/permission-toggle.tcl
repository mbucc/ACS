# /www/gp/permission-toggle.tcl

ad_page_contract {
    Given form input that identifies a specific permission,
    deletes the permission if it already exists or inserts
    it if it does not.

    @author michael@arsdigita.com
    @creation-date 2000-02-25
    @cvs-id permission-toggle.tcl,v 3.7.6.5 2000/07/21 04:00:13 ron Exp
} {
    on_what_id:naturalnum,notnull
    on_which_table:notnull
    object_name:notnull
    scope:notnull
    user_id:naturalnum,optional
    group_id:naturalnum,optional
    role:optional
    permission_type:notnull
    return_url:notnull
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



ad_require_permission $local_user_id "administer" $on_what_id $on_which_table

# Does the specified permission exist?
#
switch $scope {
    user {
	set permission_id [db_string gp_user_select "select
 ad_general_permissions.user_permission_id(:user_id, :permission_type, :on_what_id, :on_which_table)
from dual"]
    }

    group_role {
	set permission_id [db_string gp_grouprole_select "select
 ad_general_permissions.group_role_permission_id(:group_id, :role, :permission_type, :on_what_id, :on_which_table)
from dual"]
    }

    group {
	set permission_id [db_string gp_group_select "select
 ad_general_permissions.group_permission_id(:group_id, :permission_type, :on_what_id, :on_which_table)
from dual"]
    }

    registered_users {
	set permission_id [db_string gp_regusers_select "select
 ad_general_permissions.reg_users_permission_id(:permission_type, :on_what_id, :on_which_table)
from dual"]
    }

    all_users {
	set permission_id [db_string gp_allusers_select "select
 ad_general_permissions.all_users_permission_id(:permission_type,
  :on_what_id, :on_which_table)
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
	&& [ad_permission_count $on_what_id $on_which_table \
		$permission_type] == 1
    } {
	db_release_unused_handles

	ad_returnredirect "revoke-only-administer-permission?[export_url_vars on_what_id on_which_table object_name permission_id return_url]"
	return

    } else {
	db_dml gp_permission_revoke "begin
 ad_general_permissions.revoke_permission($permission_id);
end;"
    }

} else {
    # Otherwise, grant the permission.
    #
    # to do: what to replace ns_ora exec_plsql $db with???
db_with_handle db {
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
}

ad_returnredirect $return_url
