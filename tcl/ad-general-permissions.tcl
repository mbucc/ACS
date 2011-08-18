# $Id: ad-general-permissions.tcl,v 3.4.2.2 2000/04/28 15:08:09 carsten Exp $
# procs for gp (see /doc/general-permissions.html)
# richardl@arsdigita.com
# rewritten by michael@arsdigita.com, yon@arsdigita.com, 2000-02-25

util_report_library_entry

proc_doc ad_user_has_permission_p {db user_id permission_type on_what_id on_which_table} {Returns true (1) if the specified user has the requested type of permission on the specified row in the specified table; otherwise, returns false (0).} {
    return [database_to_tcl_string $db "select
 decode(ad_general_permissions.user_has_row_permission_p($user_id, '$permission_type', '$on_what_id', '$on_which_table'), 't', 1, 0)
from dual"]
}

proc_doc ad_user_has_row_permission_p {db user_id permission_type on_what_id on_which_table} {<strong>Deprecated:</strong> use <code>ad_user_has_permission_p</code> instead.} {
    return [ad_user_has_permission_p $db $user_id \
	    $permission_type $on_what_id $on_which_table]
}

proc_doc ad_require_permission {db user_id permission_type on_what_id on_which_table {return_url ""}} {If the user is not logged in and the specified type of permission has not been granted to all users, then redirect for registration. If the user is logged in but does not have the specified permission type on the specified database row, then redirects to <code>return_url</code> if supplied, or returns a "forbidden" error page.} {

    if { [string compare $user_id 0] == 0 } {
	set all_users_have_permission_p [database_to_tcl_string $db "select
 decode(ad_general_permissions.all_users_permission_id('$permission_type', '$on_what_id', '$on_which_table'), 0, 0, 1)
from dual"]

	if { !$all_users_have_permission_p  } {
	    ns_db releasehandle $db
	    ad_redirect_for_registration
	    return -code return
	}

    } elseif {
	![ad_user_has_row_permission_p $db $user_id \
		$permission_type $on_what_id $on_which_table]
    } {
	ns_db releasehandle $db

	if { ![empty_string_p $return_url] } {
	    ad_returnredirect $return_url
	} else {
	    ns_returnforbidden
	}

	return -code return
    }
}

proc_doc ad_permission_count {db on_what_id on_which_table {permission_type ""}} {Returns the number of permissions granted on the specified row in the database (of the specified permission type, if supplied).} {

    set query "select count(*)
from general_permissions
where on_what_id = $on_what_id
and on_which_table = lower('$on_which_table')"

    if { ![empty_string_p $permission_type] } {
	append query " and permission_type = '[DoubleApos $permission_type]'"
    }

    return [database_to_tcl_string $db $query]
}

util_report_successful_library_load
