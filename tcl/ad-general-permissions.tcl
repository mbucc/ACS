# /tcl/ad-general-permissions.tcl

ad_library {

    procs for gp (see /doc/general-permissions.html)

    @author richardl@arsdigita.com
    @author michael@arsdigita.com
    @author yon@arsdigita.com

    @created 2000-02-25

    @cvs-id ad-general-permissions.tcl,v 3.7.2.4 2000/09/14 07:36:28 ron Exp
}

proc_doc ad_user_has_permission_p {user_id permission_type on_what_id on_which_table} {Returns true (1) if the specified user has the requested type of permission on the specified row in the specified table; otherwise, returns false (0).} {
    return [db_string permissions_select "select
 decode(ad_general_permissions.user_has_row_permission_p($user_id, '$permission_type', '$on_what_id', '$on_which_table'), 't', 1, 0)
from dual"]
}

proc_doc ad_user_has_row_permission_p {user_id permission_type on_what_id on_which_table} {<strong>Deprecated:</strong> use <code>ad_user_has_permission_p</code> instead.} {
    return [ad_user_has_permission_p $user_id \
	    $permission_type $on_what_id $on_which_table]
}

proc_doc ad_require_permission {user_id permission_type on_what_id on_which_table {return_url ""}} {If the user is not logged in and the specified type of permission has not been granted to all users, then redirect for registration. If the user is logged in but does not have the specified permission type on the specified database row, then redirects to <code>return_url</code> if supplied, or returns a "forbidden" error page.} {

    if { [string compare $user_id 0] == 0 } {
	set all_users_have_permission_p [db_string permission_req_select "select
 decode(ad_general_permissions.all_users_permission_id(:permission_type, :on_what_id, :on_which_table), 0, 0, 1)
from dual"]

	if { !$all_users_have_permission_p  } {
	    db_release_unused_handles
	    ad_redirect_for_registration
	    ad_script_abort
	}

    } elseif {
	![ad_user_has_row_permission_p $user_id \
		$permission_type $on_what_id $on_which_table]
    } {
	db_release_unused_handles

	if { ![empty_string_p $return_url] } {
	    ad_returnredirect $return_url
	} else {
	    ns_returnforbidden
	}

	ad_script_abort
    }
}

proc_doc ad_permission_count {on_what_id on_which_table {permission_type ""}} {Returns the number of permissions granted on the specified row in the database (of the specified permission type, if supplied).} {

    set query "select count(*)
from general_permissions
where on_what_id = :on_what_id
and on_which_table = lower('$on_which_table')"

    if { ![empty_string_p $permission_type] } {
	append query " and permission_type = '[DoubleApos $permission_type]'"
    }

    return [db_string id_count_select $query]
}
