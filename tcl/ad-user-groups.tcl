# $Id: ad-user-groups.tcl,v 3.3.2.1 2000/04/28 15:08:15 carsten Exp $
# created by philg@mit.edu 11/16/98
#
# extensively modified by teadams@mit.edu and folded into
# ACS for version 1.4 to support the /doc/permission.html system
#
# procedures to support the grouping of users
# into arbitrary groups of arbitrary type
# (see /doc/sql/user-groups.sql)

# modified by teadams@Mit.edu to use group_id cookie

proc ad_user_group_helper_table_name {group_type} {
    return "[string trim $group_type]_info"
}

proc_doc ad_user_group_authorized_admin { user_id group_id db } { Returns 1 if the user has a role of administrator. 0 otherwise. } {
    set n_rows [database_to_tcl_string $db "select count(*) from user_group_map where user_id = $user_id and group_id = $group_id and lower(role) = 'administrator'"]
    if { $n_rows > 0 } {
	return 1
    } else {
	return 0
    }
} 

proc_doc ad_user_group_authorized_admin_or_site_admin { user_id group_id db } { Returns 1 if the user has a role of administrator for the specified group OR if the user is a site-wide administrator. 0 otherwise. } {
    if [ad_administrator_p $db $user_id] {
	return 0 
    } else {
	# user is not a site-wide admin, but they might be a group admin
	set n_rows [database_to_tcl_string $db "select count(*) from user_group_map where user_id = $user_id and group_id = $group_id and lower(role) = 'administrator'"]
	if { $n_rows > 0 } {
	    return 1
	} else {
	    return 0
	}
    }
}

proc_doc ad_user_group_member { db group_id {user_id ""} } { Returns 1 if user is a member of the group. 0 otherwise.} {

    if [empty_string_p $user_id] {
	set user_id [ad_verify_and_get_user_id]
    }

    set n_rows [database_to_tcl_string $db "select count(*) from user_group_map where user_id =$user_id and group_id = $group_id"]
    if { $n_rows > 0 } {
	return 1
    } else {
	return 0
    }
} 

proc ad_user_group_member_cache_internal {group_id user_id} {
    set db [ns_db gethandle subquery]
    set value [ad_user_group_member $db $group_id $user_id]
    ns_db releasehandle $db
    return $value
}

proc_doc ad_user_group_member_cache { group_id user_id } { Wraps util_memoize around ad_user_group_member.  Gets its own db handle if necessary.  Returns 1 if user is a member of the group. 0 otherwise.} {
    return [util_memoize "ad_user_group_member_cache_internal $group_id $user_id" [ad_parameter CacheTimeout ug 600]]
}

proc_doc ad_administration_group_member { db module {submodule ""} {user_id ""} } "Returns 1 is user is a member of the administration group.  0 otherwise." {
    set group_id [ad_administration_group_id $db $module $submodule]
    if {[empty_string_p $group_id]} {
	return 0
    } else {
	return [ad_user_group_member $db $group_id $user_id]
    }
}


proc_doc ad_administration_group_add {db pretty_name module {submodule "" } {url ""} {multi_role_p "f"} {group_id ""}} "Creates an administration group. Returns: The group_id of the new group if it is created; The group_id of an old group if there was already a administration group for this module and submodule; 0 otherwise. Notice that unique short_name for group is genereted from pretty_name" {
    
    # PARAMETERS
    # db: database handle
    # pretty_name: pretty name of the group
    # module: module this is created for, ie. 'classifieds'
    # submodule: submodule this is created for, ie. 'equipment', 'jobs', 'wtr'
    # url: url of the module administration page
    # permission system: which type of permission system you would like to run (basic or advanced)
    # group_id (optional): group id of the new group. One will be generated if it is not specified
    
    set extra_values [ns_set create extra_values]
    ns_set put $extra_values module $module
    ns_set put $extra_values submodule $submodule
    ns_set put $extra_values url $url

    set group_id [ad_user_group_add $db "administration" $pretty_name "t" "f" "closed" $multi_role_p $extra_values $group_id]

    if { $group_id == 0} {
	# see if this group is defined already
	set selection [ns_db 0or1row $db "select group_id from administration_info where module='[DoubleApos $module]' and submodule='[DoubleApos $submodule]'"]
	if [empty_string_p $selection] {
	    return 0
	} else {
	    set_variables_after_query
	    return $group_id
	}
    }
    return $group_id
}


proc_doc ad_user_group_add {db group_type group_name {approved_p "t"}  {existence_public_p "f"} {new_member_policy "closed"} {multi_role_p "f"} {extra_values ""}  {group_id "" }} "Creates a new group. Returns: The groud_id of the group if created or it existed already (double click protection); 0 on failure." {

    # PARAMETERS
    # db: database handle
    # group_type: type of group
    # group_name: pretty name
    # approved_p (optional): is this an approved group?
    # existence_public_p (optional): Is the existence of this group public?
    # new_member_policy (optional): How can members join? (wait, closed, open)
    # permission_system(optional): What type of permission system (basic, advanced)
    # extra_values (optional): A ns_set containing 
    #     extra values that should be stored for this
    #     group.  These are items that will go in the [set group_type]_info
    #     tables. The keys of the ns_set contain the column names. The values
    #     contain the values.
    # group_id (optional): Group_id. If this is null, one will be created

    
    if [empty_string_p $group_id] {
	set group_id [database_to_tcl_string $db "select user_group_sequence.nextval from dual"]
    }

    ns_db dml $db "begin transaction"

    if [catch {
	set short_name [database_to_tcl_string $db "
	select short_name_from_group_name('[DoubleApos $group_name]') from dual"]

	ns_db dml $db "
	insert into user_groups
	(group_id, group_type, group_name, short_name, approved_p, existence_public_p, new_member_policy, multi_role_p,
 	creation_user, creation_ip_address, registration_date)
	values ($group_id, '[DoubleApos $group_type]', '[DoubleApos $group_name]', '[DoubleApos $short_name]',
	'$approved_p', '$existence_public_p', '[DoubleApos $new_member_policy]', '[DoubleApos $multi_role_p]',
	[ad_get_user_id], '[DoubleApos [ns_conn peeraddr]]', sysdate)"   

    } errmsg] {
	ns_db dml $db "abort transaction"
	ns_log Error "$errmsg in ad-user_groups.tcl - ad_user_group_add insertion into user groups"

	# see if this group is already defined
	
	set selection [ns_db 0or1row $db "select group_id from user_groups where group_id = $group_id"]
	if [empty_string_p $selection] {
	    return 0
	} else {
	    set_variables_after_query
	    return $group_id
	}
    }
    
    # insert the extra values
    if ![empty_string_p $extra_values] {
	set extra_values_i 0
	lappend columns group_id
	lappend values $group_id
	
	set extra_values_limit [ns_set size $extra_values]
	while {$extra_values_i < $extra_values_limit} {
	    set key [ns_set key $extra_values $extra_values_i] 
	    lappend columns $key
	    lappend values '[DoubleApos [ns_set get $extra_values $key]]'
	    incr extra_values_i
	}
	if [catch {
	    ns_db dml $db "insert into [set group_type]_info ([join $columns ","]) values ([join $values ","])"
	} errmsg] {
	    # There was an error inserting the extra information (most likely to this is an administration group
	    # and the module and submodule are already there)
	    ns_db dml $db "abort transaction"
	    ns_log Error "$errmsg in ad-user_groups.tcl - ad_user_group_add extra values insertion"
	    return 0
	}
    }

    ns_db dml $db "end transaction"

    return $group_id
}


proc_doc ad_permission_p {db {module ""} {submodule ""} {action ""} {user_id ""} {group_id ""}} {For groups with basic administration: Returns 1 if user has a role of administrator or all; O otherwise. For groups with advanced administration: Returns 1 if user has authority for the action; 0 otherwise.} {

    if { ![empty_string_p $module] && ![empty_string_p $group_id] } {
	error "specify either module or group_id, not both"
    }

    # If no user_id was specified, then use the ID of the logged-in
    # user.
    #
    if [empty_string_p $user_id] {
	set user_id [ad_verify_and_get_user_id]
    }

    # Identify the group. Either the group_id will be explicitly
    # specified or we derive it from the module by querying to
    # find out which group is the administration group for the
    # module. If submodule is specified in addition to module, then
    # find out which group is the administration group for the
    # submodule.
    #
    if { [empty_string_p $group_id] } {
	set group_id [ad_administration_group_id $db $module $submodule]

	# If we fail to find a corresponding group_id, return false.
	# This probably should raise an error but I (Michael Y) don't
	# want to risk breaking any more code right now.
	#
	if { [empty_string_p $group_id] } {
	    return 0
	}
    }

    # Next, find out if the group use basic or advanced (a.k.a.
    # multi-role) administration.
    #
    set multi_role_p [database_to_tcl_string $db "select multi_role_p from user_groups where group_id = $group_id"]

    if { $multi_role_p == "f" } {
	# If administration is basic, then return true if the user has
	# either the 'administrator' role or the 'all' role for the
	# group.
	#
	set permission_p [database_to_tcl_string $db "select decode(count(*), 0, 0, 1) from user_group_map where user_id = $user_id and group_id = $group_id and role in ('administrator', 'all')"]

    } else {
	# If administration is advanced, then check to see if the
	# user is an administrator; if not, make sure that action
	# was specified and then check to see if the user has a
	# role that is authorized to perform the specified action.
	#
	set permission_p [database_to_tcl_string $db "select decode(count(*), 0, 0, 1) from user_group_map where user_id = $user_id and group_id = $group_id and role = 'administrator'"]

	if { !$permission_p } {
	    if { [empty_string_p $action] } {
		error "no action specified for group with multi-role administration (ID $group_id)"
	    }

	    set permission_p [database_to_tcl_string $db "select decode(count(*), 0, 0, 1) from user_group_action_role_map where group_id = $group_id and action = '[DoubleApos $action]' and role in (select role from user_group_map where group_id = $group_id and user_id = $user_id)"]
	}
    }

    # If necessary, make a final check to see if the user is a
    # site-wide administrator.
    #
    if { !$permission_p } {
	set permission_p [ad_administrator_p $db $user_id]
    }

    return $permission_p
}

proc_doc ad_administration_group_id {db module {submodule ""}} "Given the module and submodule of an administration group, returns the group_id.  Returns empty string if there isn't a group." {
    if ![empty_string_p $submodule] {
	set query "select group_id 
from administration_info 
where module = '[DoubleApos $module]' 
and submodule = '[DoubleApos $submodule]'"
    } else {
	set query "select group_id 
from administration_info 
where module = '[DoubleApos $module]' 
and submodule is null"
    }
    return [database_to_tcl_string_or_null $db $query]
}

proc_doc ad_administration_group_user_add { db user_id role module submodule } "Adds a user to an administration group or updates his/her role. Returns: 1 on success; 0 on failure." {
    set group_id [ad_administration_group_id $db $module $submodule]
    if {[empty_string_p $group_id]} {
	return 0
    } else {
	return [ad_user_group_user_add $db $user_id $role $group_id] 
    }
}

proc_doc ad_user_group_user_add { db user_id role group_id } {Maps the specified user to the specified group in the specified role; if the mapping already exists, does nothing.} {
    
    if [catch {
    ns_db dml $db "insert into user_group_map(user_id, group_id, role, mapping_user, mapping_ip_address)
values ($user_id, $group_id, '[DoubleApos $role]',[ad_get_user_id],'[DoubleApos [ns_conn peeraddr]]')" } errmsg] {

    # if the insert failed for a reason other than the fact that the
    # mapping already exists, then raise the error
    #
    if {
	[database_to_tcl_string $db "select count(*) from
	user_group_map
	where user_id = $user_id and group_id = $group_id and role = '[DoubleApos $role]'"] == 0
    } {
	error $errmsg
    }

    return 1
}
}


proc_doc ad_user_group_role_add {db group_id role} "Inserts a role into a user group." {
    ns_db dml $db "insert into user_group_roles (group_id, role, creation_user, creation_ip_address) select $group_id, '[DoubleApos $role]', [ad_get_user_id], '[DoubleApos [ns_conn peeraddr]]' from dual where not exists (select role from user_group_roles where group_id = $group_id and role = '[DoubleApos $role]')"
}


proc_doc ad_administration_group_role_add { db module submodule role } "Inserts a role into an administration group." {
    set group_id [ad_administration_group_id $db $module $submodule]
    if {[empty_string_p $group_id]} {
	return 0
    } else {
	ad_user_group_role_add $db $group_id $role
	return 1
    }
}


proc_doc ad_user_group_action_add {db group_id action} "Inserts a action into a user_group." {
    ns_db dml $db "insert into user_group_actions (group_id, action, creation_user, creation_ip_address) select $group_id, '[DoubleApos $action]', [ad_get_user_id], '[DoubleApos [ns_conn peeraddr]]' from dual where not exists (select action from user_group_actions where group_id = $group_id and action = '[DoubleApos $action]')"
}


proc_doc ad_administration_group_action_add { db module submodule action } "Inserts an action into an administration group." {
    set group_id [ad_administration_group_id $db $module $submodule]
    if {[empty_string_p $group_id]} {
	return 0
    } else {
	ad_user_group_action_add $db $group_id $action
	return 1
    }
}


proc_doc ad_user_group_action_role_map {db group_id action role} "Maps an action to a role a user group." {
    ns_db dml $db "insert into user_group_action_role_map (group_id, role, action, creation_user, creation_ip_address) select $group_id, '[DoubleApos $role]', '[DoubleApos $action]', [ad_get_user_id], '[DoubleApos [ns_conn peeraddr]]' from dual where not exists (select role from user_group_action_role_map where group_id = $group_id and role = '[DoubleApos $role]' and action = '[DoubleApos $action]')"
}


proc_doc ad_administration_group_action_role_map { db module submodule action role } "Maps an action to a role in an administration group." {
    set group_id [ad_administration_group_id $db $module $submodule]
    if {[empty_string_p $group_id]} {
	return 0
    } else {
	ad_user_group_action_role_map $db $group_id $action $role
	return 1
    }
}

proc_doc ad_user_group_type_field_form_element { field_name column_type {default_value ""} } "Creates a HTML form fragment of a type appropriate for the type of data expected (e.g. radio buttons if the type is boolean).  The column_type can be any of the following: integer, number, date, text (up to 4000 characters), text_short (up to 200 characters), boolean, and special (no form element will be provided)." {
    if { $column_type == "integer" || $column_type == "number"} {
	return "<input type=text name=\"$field_name\" value=\"[philg_quote_double_quotes $default_value]\" size=5>"
    } elseif { $column_type == "date" } {
	return [ad_dateentrywidget $field_name $default_value]
    } elseif { $column_type == "text_short" } {
	return "<input type=text name=\"$field_name\" value=\"[philg_quote_double_quotes $default_value]\" size=30 maxlength=200>"
    } elseif { $column_type == "text" } {
	return "<textarea wrap name=\"$field_name\" rows=8 cols=50>$default_value</textarea>"
    } elseif { $column_type == "special" } {
	return "Special field."
    } else {
	# it's boolean
	set to_return ""
	if { [string tolower $default_value] == "t" || [string tolower $default_value] == "y" || [string tolower $default_value] == "yes"} {
	    append to_return "<input type=radio name=\"$field_name\" value=t checked>Yes &nbsp;"
	} else {
	    append to_return "<input type=radio name=\"$field_name\" value=t>Yes &nbsp;"
	}
	if { [string tolower $default_value] == "f" || [string tolower $default_value] == "n" || [string tolower $default_value] == "no"} {
	    append to_return "<input type=radio name=\"$field_name\" value=f checked>No"
	} else {
	    append to_return "<input type=radio name=\"$field_name\" value=f>No"
	}
	return $to_return
    }
}

proc_doc ad_user_group_column_type_widget { {default ""} } "Returns an HTML form fragment containing all possible values of column_type" {
    return "<select name=\"column_type\">
<option value=\"boolean\" [ec_decode $default "boolean" "selected" ""]>Boolean (Yes or No)
<option value=\"integer\" [ec_decode $default "integer" "selected" ""]>Integer (Whole Number)
<option value=\"number\" [ec_decode $default "number" "selected" ""]>Number (e.g., 8.35)
<option value=\"date\" [ec_decode $default "date" "selected" ""]>Date
<option value=\"text_short\" [ec_decode $default "text_short" "selected" ""]>Short Text (up to 200 characters)
<option value=\"text\" [ec_decode $default "text" "selected" ""]>Long Text (up to 4000 characters)
<option value=\"special\" [ec_decode $default "boolean" "special" ""]>Special (no form element will be provided)
</select> (used for user interface)
"
}

proc_doc ad_get_group_id {} "Returns the group_id cookie value. Returns 0 if the group_id cookie is missing, if the user is not logged in, or if the user is not a member of the group."  {
    # 1 verifies the user_id cookie 
    # 2 gets the group_id cookie
    # 3 verifies that the user_id is mapped to group_id 

    ns_share ad_group_map_cache

    set user_id [ad_verify_and_get_user_id]
    if { $user_id == 0 } {
	return 0
    }
    set headers [ns_conn headers]
    set cookie [ns_set get $headers Cookie]
    if { [regexp {ad_group_id=([^;]+)} $cookie {} group_id] } {
	if { [info exists ad_group_map_cache($user_id)] } {
	    # there exists a cached $user_id to $group_id mapping
	    if { [string compare $group_id $ad_group_map_cache($user_id)] == 0 } {
		return $group_id
	    } 
	}
	# we continue and hit db even if there was a cached group_id (but 
	# it didn't match) because the user might have just logged into 
	# a different group

	set db [ns_db gethandle subquery]

	if {
	    [database_to_tcl_string $db "select ad_group_member_p($user_id, $group_id) from dual"] == "t"
	} {
	    set ad_group_map_cache($user_id) $group_id
	    ns_db releasehandle $db
	    return $group_id
	} else {
	    ns_db releasehandle $db
	    # user is not in the group
	    return 0
	}
    } else {
	return 0
    }
}


proc_doc ad_get_group_info {} "Binds variables to user group properties. Assumes group_id and db are defined."  {
    # assumes that group_id and db are set
    uplevel {
	set selection [ns_db 0or1row $db "select user_groups.* 
from user_groups
where  user_groups.group_id = $group_id"]
        if ![empty_string_p $selection] {
	    set_variables_after_query
	    # see if there is an _info table for this user_group type
	    set info_table_name [ad_user_group_helper_table_name $group_type] 

	    if [ns_table exists $db $info_table_name] {
		set selection [ns_db 0or1row $db "select * from $info_table_name where group_id = $group_id"]
		if ![empty_string_p $selection] {
		    set_variables_after_query
		}
	    }
	}
    }
}



