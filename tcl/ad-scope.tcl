ad_library {
    @date December 1999
    @author tarik@arsdigita.com
    @cvs-id ad-scope.tcl,v 3.9.2.5 2000/09/07 21:01:31 kevin Exp
}

proc_doc ad_scope_upvar_level {} { Returns the level at which to perform uplevels and upvars (#1, or #2 if we're using the abstract URL procs, i.e., ad_conn(canonical_url) exists). } {
    global ad_conn
    if { [info exists ad_conn(canonical_url)] } {
	return \#3
    } else {
	return \#2
    }
}

proc_doc ad_scope_sql { {table_name ""} } "if scope is not set in the topmost environment then public scope is assumed. if scope=group it assumes group_id is set in the topmost environment, if scope=user it assumes that user_id is set in topmost environment and if scope=table it assumes on_which_table and on_what_id are set in topmost environment. ad_scope_sql returns portion of sql query resolving scope. e.g. if scope=group this proc will return scope=group and group_id=<group_id>. to avoid naming conflicts you may specify a table name (or table alias name) of the table for which we are checking the scope. (e.g if table_name=news, then nnews.scope will be used instead of just scope)" {
    if { [uplevel [ad_scope_upvar_level] {info exists scope}] } {
	upvar [ad_scope_upvar_level] scope scope
    } else {
	set scope public
    }

    if { [empty_string_p $table_name] } {
	switch $scope {
	    public {
		return "scope='public'"
	    }
	    
	    group {
		upvar [ad_scope_upvar_level] group_id group_id
		return "scope='group' and group_id=$group_id"
	    }
	    
	    user {
		upvar [ad_scope_upvar_level] user_id user_id
		return "scope='user' and user_id=$user_id"
	    }
	    table {
		upvar [ad_scope_upvar_level] on_which_table on_which_table
		upvar [ad_scope_upvar_level] on_what_id on_what_id
		return "scope='table' and on_which_table='$on_which_table' and on_what_id=$on_what_id"
	    }
	}
    } else {
	switch $scope {
	    public {
		return "$table_name\.scope='public'"
	    }
	    
	    group {
		upvar [ad_scope_upvar_level] group_id group_id
		return "$table_name\.scope='group' and $table_name\.group_id=$group_id"
	    }
	    
	    user {
		upvar [ad_scope_upvar_level] user_id user_id
		return "$table_name\.scope='user' and $table_name\.user_id=$user_id"
	    }
	    table {
		upvar [ad_scope_upvar_level] on_which_table on_which_table
		upvar [ad_scope_upvar_level] on_what_id on_what_id
		return "$table_name\.scope='table' and 
		$table_name\.on_which_table='$on_which_table' 
		and $table_name\.on_what_id=$on_what_id"
	    }
	}
    }
}

proc_doc ad_scope_cols_sql {} "if scope is not set in the topmost environment then public scope is assumed. if scope=group it assumes group_id is set in the topmost environment, if scope=user it assumes that user_id is set in topmost environment and if scope=table it assumes on_which_table and on_what_id are set in topmost environment. ad_scope_sql returns columns that need to be updated in an insert statement. e.g. if scope=group this proc will return scope, group_id" {
    if { [uplevel [ad_scope_upvar_level] {info exists scope}] } {
	upvar [ad_scope_upvar_level] scope scope
    } else {
	set scope public
    }

    uplevel [ad_scope_upvar_level] {
	switch $scope {
	    public {
		return "scope"
	    }
	    
	    group {
		return "scope, group_id"
	    }
	    
	    user {
		return "scope, user_id"
	    }
	    table {
		return "scope, on_which_table, on_what_id"
	    }
	}
    }
    
}

proc_doc ad_scope_vals_sql {} "if scope is not set in the topmost environment then public scope is assumed. if scope=group it assumes group_id is set in the topmost environment and if scope=user it assumes that user_id is set in topmost environment and if scope=table it assumes on_which_table and on_what_id are set in topmost environment. ad_scope_sql returns values that need to be inserted in an insert statement. e.g. if scope=group this proc will return '\$scope', \$group_id" {
    if { [uplevel [ad_scope_upvar_level] {info exists scope}] } {
	upvar [ad_scope_upvar_level] scope scope
    } else {
	set scope public
    }

    uplevel [ad_scope_upvar_level] {
	switch $scope {
	    public {
		return "'$scope'"
	    }
	    
	    group {
		return "'$scope', $group_id"
	    }
	    
	    user {
		return "'$scope', $user_id"
	    }
	    table {
		return "'$scope', '$on_which_table', '$on_what_id'"
	    }
	}
    }
}

proc_doc ad_scope_authorization_status { scope public_permissions group_permissions user_permissions {id 0} } "this procedure will check whether the visitor has the right to view the page. if authorization fails, procedure returns not_authorized; if authorization suceeds, procedure will return authorized, and if user needs to be registered in order to view the page, procedure will return reg_required. public_permission gives permissions used for public scope: all, registered, admin (site-wide-administrator) and none (scope=public does not apply for this page, so nobody can see the page). group_permissions gives permission used for scope group: all (all users), registered (registered users only), group_member (group members only), group_admin (group administrators), admin (site wide administrators) and none (scope=group does not apply for this page, so nobody in the group can see the page). user_permissions gives permission used for scope user: all (all users), registered (registered users only) and user (only the user with user_id specified by the variable user_id_name has full privileges), and none (scope=user does not apply for this page, so page cannot be accessed for scope user). if scope=group, id is the group_id of the group against which, we are performing the authorization). if scope=user, id is the user_id of the user against whom, we are performing the authorization. if scope=public, id is irrelevant." {
    
    set visitor_id [ad_verify_and_get_user_id]

    switch $scope {
	public {
	    switch $public_permissions {
		all {
		    return authorized
		}
		registered {
		    return [ad_decode $visitor_id 0 reg_required authorized]
		}
		admin {
		    if { $visitor_id==0 } {
			return reg_required
		    }
		    return [ad_decode [ad_administrator_p $visitor_id] 1 authorized not_authorized]
		}
		none {
		    return not_authorized
		}
		default {
		    return not_authorized
		}
	    }
	}
	group {
	    switch $group_permissions {
		all {
		    return authorized
		}
		registered {
		    return [ad_decode $visitor_id 0 reg_required authorized]
		}
		group_member {
		    if { $visitor_id==0 } {
			return reg_required
		    }
		    return [ad_decode [ad_user_group_member $id $visitor_id] 1 authorized not_authorized]
		}
		group_admin {
		    if { $visitor_id==0 } {
			return reg_required
		    }
		    return [ad_decode [ad_user_group_authorized_admin $visitor_id $id] 1 authorized not_authorized]
		}
		admin {
		    if { $visitor_id==0 } {
			return reg_required
		    }
		    return [ad_decode [ad_administrator_p $visitor_id] 1 authorized not_authorized]
		}
		none {
		    return not_authorized
		}
		default {
		    return not_authorized
		}
	    }
	}
	user {
	    switch $user_permissions {
		all {
		    return authorized
		}
		registered {
		    return [ad_decode $visitor_id 0 reg_required authorized]
		}
		user {
		    if { $visitor_id==0 } {
			return reg_required
		    }
		    return [ad_decode $id $visitor_id authorized not_authorized]
		}
		admin {
		    if { $visitor_id==0 } {
			return reg_required
		    }
		    return [ad_decode [ad_administrator_p $visitor_id] 1 authorized not_authorized]
		}
		none {
		    return not_authorized
		}
		default {
		    return not_authorized
		}
	    }
	}
	default {
	    return not_authorized
	}
    }
}

proc_doc ad_scope_authorize {scope public_permissions group_permissions user_permissions {group_id_name ""} {user_id_name ""} } "this procedure will check whether the visitor has the right to view the page. if authorization fails, procedure will returns not_authorized message to the user; if authorization suceeds, procedure will return user_id of the visitor if user is logged in or 0 otherwise. if user needs to be registered in order to view the page, procedure will automatically redirect the user. in the case, user is not authorized or he i s redirected, procedure will return from the topmost environment. public_permission gives permissions used for public scope: all, registered, admin (site-wide-administrator) and none (scope=public does not apply for this page, so nobody can see the page). group_permissions gives permission used for scope group: all (all users), registered (registered users only), group_member (group members only), group_admin (group administrators), admin (site wide administrators) and none (scope=group does not apply for this page, so nobody in the group can see the page). user_permissions gives permission used for scope user: all (all users), registered (registered users only) and user (only the user with user_id specified by the variable user_id_name has full privileges), and none (scope=user does not apply for this page, so page cannot be accessed for scope user). if group_id_name (name of the group_id variable against which, we are testing the authorization) is not provided and scope=group, procedure assumes that group_id is set in the topmost environment. if user_id_name (name of the user_id variable against which, we are testing the authorization) is not provided and scope=group, procedure assumes that user_id is set in the topmost environment." {

    # set the appropriated id for the ad_scope_authorization_status procedure
    switch $scope {
	public {
	    set id 0
	}
	group {
	    if { [empty_string_p $group_id_name] } {
		upvar [ad_scope_upvar_level] group_id id
	    } else {
		upvar [ad_scope_upvar_level] group_id_name id
	    }
	}
	user {
	    if { [empty_string_p $user_id_name] } {
		upvar [ad_scope_upvar_level] user_id id
	    } else {
		upvar [ad_scope_upvar_level] user_id_name id
	    }
	}
	default {
	    error "unknown scope"
	}
    }
    
    set authorization_status [ad_scope_authorization_status $scope $public_permissions $group_permissions $user_permissions $id]
    set user_id [ad_verify_and_get_user_id]
    switch $authorization_status {
	authorized {
	    return $user_id
	}
	not_authorized {
	    ad_return_warning "Not authorized" "You are not authorized to see this page"
	    ad_script_abort
	}
	reg_required {
	    ad_redirect_for_registration
	    ad_script_abort
	}
    }
}

proc_doc ad_scope_administrator_p { visitor_id } "if scope is not set in the topmost environment then public scope is assumed. if scope=group, it assumes that group_id is set in the topmost environment. if scope=user it assumes that user_id is set in topmost environment (this is user_id of the user who has permission to this page). this procedure will check whether the visitor has the administration rights over the page. if scope=public only site-wide administrator has the right to see the page. if scope=group only administrators of the groups specifed by the group_id are allowed to access the page. if scope=user, only user specified by user_id is allowed to view the page. procedure will return 1 if visitor with user_id equal to visitor_id has right to see the page, otherwide procedure will return 0." {
    if { [uplevel [ad_scope_upvar_level] {info exists scope}] } {
	upvar [ad_scope_upvar_level] scope scope
    } else {
	set scope public
    }

    switch $scope {
	public {
	    return [ad_administrator_p $visitor_id]
	}
	group {
	    upvar [ad_scope_upvar_level] group_id group_id
	    return [ad_user_group_authorized_admin $visitor_id $group_id]
	}
	user {
	    upvar [ad_scope_upvar_level] user_id user_id
	    if { $user_id==$visitor_id } {
		return 1
	    } else {
		return 0
	    }
	}
    }
}

proc_doc ad_scope_error_check { {default_scope public} } "this procedure does scope error checking. if scope is not set in topmost environment, then the scope will be set to the value of default_scope. if scope=group this procedure will check whether group_id is provided and if not it will return error to the user. if scope=table and on_which_table or on_what_id are not provided this procedure will return error to the user. if everything went fine this procedure returns 1. if scope=group and the group_vars_set is not set in the topmost environment, then this procedure will set group_vars_set variables corresponding to the group_id. if scope=user and user_id is not provided, then user_id will be set to the user_id of the visitor if visitor is logged in, otherwise error will be returned to the user." {

    if { [uplevel [ad_scope_upvar_level] {info exists scope}] } {
	upvar [ad_scope_upvar_level] scope scope
    } else {
	set scope $default_scope
	# create scope in topmost environment and give it initial value of 0
	uplevel [ad_scope_upvar_level] { set scope 0 }
	upvar [ad_scope_upvar_level] scope new_scope
	# set scope in the topmost environment to the value of default_scope
	set new_scope $default_scope
    }

    switch $scope {
	public {
	    return 1
	}
	group {
	    if { ![uplevel [ad_scope_upvar_level] {info exists group_id}] } {
		ad_return_error "Error: group_id not supplied" \
			"<ul><li>group_id must be supplied in order to access this page.</ul>"
		ad_script_abort
	    } else {
		upvar [ad_scope_upvar_level] group_id group_id
		
		# in the case group_vars_set was not provided, put default values to this set
		if { ![uplevel [ad_scope_upvar_level] {info exists group_vars_set}] } {
		    
		    set bind_vars [ad_tcl_vars_to_ns_set group_id]
		    set sql_qry "
		    select group_name, short_name, admin_email from user_groups where group_id=:group_id"
		    set return_count [db_0or1row "scope_get_names" $sql_qry -bind $bind_vars]
		    db_release_unused_handles
		    
		    if { $return_count == 0 } {
			# Invalid group id provided
			ad_return_error "Error: invalid group_id not supplied" \
				"<ul><li>The specified group_id, #$group_id, does not exist</ul>"
			ad_script_abort
		    }

		    uplevel [ad_scope_upvar_level] { set group_vars_set [ns_set create] }
		    upvar [ad_scope_upvar_level] group_vars_set group_vars_set

		    ns_set put $group_vars_set group_id $group_id
		    ns_set put $group_vars_set group_short_name $short_name
		    ns_set put $group_vars_set group_name $group_name
		    ns_set put $group_vars_set group_admin_email $admin_email
		    ns_set put $group_vars_set group_public_url /[ad_parameter GroupsDirectory ug]
		    ns_set put $group_vars_set group_admin_url /[ad_parameter GroupsDirectory ug]/[ad_parameter GroupsAdminDirectory ug]
		    ns_set put $group_vars_set group_type_url_p 0
		    ns_set put $group_vars_set group_context_bar_list [list]
		    ns_set put $group_vars_set group_navbar_list [list]
		}
		return 1
	    }
	}
	user {
	    if { ![uplevel [ad_scope_upvar_level] {info exists user_id}] } {
		set user_id [ad_verify_and_get_user_id]
		if { $user_id==0 } {
		    # user is not logged in and user_id was not set in the topmost environment,
		    # so redirect the user for registration
		    ad_redirect_for_registration
		    ad_script_abort
		}
		uplevel [ad_scope_upvar_level] { set user_id 0 }
		upvar [ad_scope_upvar_level] user_id user_id_temp
		set user_id_temp $user_id
		
		return 1
	    }
	}
	table {
	    if { ![uplevel [ad_scope_upvar_level] {info exists on_which_table}] } {
		ad_return_error "Error: on_which_table is not supplied" \
			"<ul><li>on_which_table must be supplied in order to access this page.</ul>"
		ad_script_abort
	    } elseif { ![uplevel [ad_scope_upvar_level] {info exists on_what_id}] } {
		ad_return_error "Error: on_what_id is not supplied" \
			"<ul><li>on_what_id must be supplied in order to access this page.</ul>"
	    } else {
		return 1
	    }
	}
    }
}

proc_doc export_url_scope_vars { { args ""} } "assumes scope is set up in the topmost environment. if scope=group it assumes group_id is set in the topmost environment, if scope=user it assumes that user_id is set in topmost environment and if scope=table it assumes on_which_table and on_what_id are set in topmost environment. this procedure operates in the same manner as export_url_vars except that it automatically figures out and sets appropriate scope variables. (e.g. for scope=group_id, export_url_scope_vars return_url would return the following string scope=group&group_id=23&return_url=23" {
    if { [empty_string_p $args] } {
	set exported_url_vars ""
    } else {
	set url_vars [eval uplevel {"export_url_vars $args"}]
	
	if { [empty_string_p $url_vars] } {
	    set exported_url_vars ""
	} else {
	    set exported_url_vars &$url_vars
	}

    }

    if { [uplevel [ad_scope_upvar_level] {string compare $scope public}]==0 } {
	return "scope=public$exported_url_vars"
    }
    if { [uplevel [ad_scope_upvar_level] {string compare $scope group}]==0 } {
        # if this var is present, it means we're being served by ug_serve_group_pages.
        # in that case, we should *not* export the other vars that it will set up for us, or 
        # ad_page_contract will complain that the variables are already set in the environment.
        if { [uplevel [ad_scope_upvar_level] {info exists do_not_export_group_scope_vars}] } {
            regsub {^&} $exported_url_vars "" exported_url_vars
            return "$exported_url_vars"
        } else {
            upvar [ad_scope_upvar_level] group_id group_id
            return "scope=group&group_id=$group_id$exported_url_vars"
        }
    }
    if { [uplevel [ad_scope_upvar_level] {string compare $scope user}]==0 } {
	upvar [ad_scope_upvar_level] user_id user_id
	return "scope=user&user_id=$user_id$exported_url_vars"
    }
    if { [uplevel [ad_scope_upvar_level] {string compare $scope table}]==0 } {
	upvar [ad_scope_upvar_level] on_which_table on_which_table
	upvar [ad_scope_upvar_level] on_what_id on_what_id
	return "scope=table&on_which_table=[ns_urlencode $on_which_table]&on_what_id=$on_what_id$exported_url_vars"
    }
} 

proc_doc export_form_scope_vars { args } "assumes scope is set up in the topmost environment. if scope=group it assumes group_id is set in the topmost environment, if scope=user it assumes that user_id is set in topmost environment and if scope=table it assumes on_which_table and on_what_id are set in topmost environment. this procedure operates in the same manner as export_form_vars except that it automatically figures out and sets appropriate scope variables. (e.g. for scope=group_id, export_form_scope_vars return_url would return the following string <input type=hidden name=scope value=group> <input type=hidden name=group_id value=23>  <input type=hidden name=return_url value=index.tcl>" {

    if { [empty_string_p $args] } {
	set form_vars ""
    } else {
	set form_vars [eval uplevel {"export_form_vars $args"}]
    }

    if { [uplevel [ad_scope_upvar_level] {string compare $scope public}]==0 } {
	return "
	<input type=hidden name=scope value=public>
	$form_vars
	"
    }
    if { [uplevel [ad_scope_upvar_level] {string compare $scope group}]==0 } {
        # if this var is present, it means we're being served by ug_serve_group_pages.
        # in that case, we should *not* export the other vars that it will set up for us, or 
        # ad_page_contract will complain that the variables are already set in the environment.
        if { [uplevel [ad_scope_upvar_level] {info exists do_not_export_group_scope_vars}] } {
            return "
            $form_vars
            "
        } else {
            upvar [ad_scope_upvar_level] group_id group_id
            return "
            <input type=hidden name=scope value=group>\n
            <input type=hidden name=group_id value=$group_id>
            $form_vars
            "
        }
    }
    if { [uplevel [ad_scope_upvar_level] {string compare $scope user}]==0 } {
	upvar [ad_scope_upvar_level] user_id user_id
	return "
 	<input type=hidden name=scope value=user>\n
	<input type=hidden name=user_id value=$user_id>
	$form_vars
	"
    }
    if { [uplevel [ad_scope_upvar_level] {string compare $scope table}]==0 } {
	upvar [ad_scope_upvar_level] on_which_table on_which_table
	upvar [ad_scope_upvar_level] on_what_id on_what_id
	return "
 	<input type=hidden name=scope value=table>\n
	<input type=hidden name=on_which_table value=\"[philg_quote_double_quotes $on_which_table]\">\n
	<input type=hidden name=on_what_id value=$on_what_id>
	$form_vars
	"
    }
}

proc_doc ad_scope_header { page_title} "if scope is not set in the topmost environment then public scope is assumed.  if scope is group, it assumes group_vars_set is set in the topmost environment. it returns appropriate scope header." {

    if { [uplevel [ad_scope_upvar_level] {info exists scope}] } {
	upvar [ad_scope_upvar_level] scope scope
    } else {
	set scope public
    }
    switch $scope {
	public {
	    return [ad_header $page_title ""]
	}
	group {
	    upvar [ad_scope_upvar_level] group_vars_set group_vars_set
	    set group_id [ns_set get $group_vars_set group_id]
	    return [ug_header $page_title $group_id]
	}
	user {
	    # this may be later modified if we allow users to customize the display of their pages
	    return [ad_header $page_title ""]
	}
    }
}

proc_doc ad_scope_footer {} "if scope is not set in the topmost environment then public scope is assumed.  if scope is group, it assumes group_vars_set is set in the topmost environment. it returns appropriate scope admin footer." {
    if { [uplevel [ad_scope_upvar_level] {info exists scope}] } {
	upvar [ad_scope_upvar_level] scope scope
    } else {
	set scope public
    }

    switch $scope {
	public {
	    return [ad_footer]
	}
	group {
	    upvar [ad_scope_upvar_level] group_vars_set group_vars_set
	    set group_admin_email [ns_set get $group_vars_set group_admin_email]
	    return [ug_footer $group_admin_email]
	}
	user {
	    # this may be later modified if we allow users to customize the display of their pages
	    return [ad_footer]
	}
    }
}

proc_doc ad_scope_admin_header { page_title } "if scope is not set in the topmost environment then public scope is assumed.  if scope is group, it assumes group_vars_set is set in the topmost environment. it returns appropriate scope admin header" {
    if { [uplevel [ad_scope_upvar_level] {info exists scope}] } {
	upvar [ad_scope_upvar_level] scope scope
    } else {
	set scope public
    }
    
    switch $scope {
	public {
	    return [ad_header $page_title]
	}
	group {
	    upvar [ad_scope_upvar_level] group_vars_set group_vars_set
	    set group_id [ns_set get $group_vars_set group_id]
	    return [ug_header $page_title $group_id]
	}
	user {
	    # this may be later modified if we allow users to customize the display of their pages
	    return [ad_header $page_title]
	}
    }
}

proc_doc ad_scope_admin_footer {} "if scope is not set in the topmost environment then public scope is assumed.  if scope is group, it assumes group_vars_set is set in the topmost environment. returns appropriate scope admin footer. because it is only the programmers who can fix the pages, we should always use ad_footer. we mantain this as separate function for consistency and possible future changes in display, in which case this function may return something else than ad_footer" {
    return [ad_footer]
}

proc_doc ad_scope_page_title { page_title {show_logo_p 1} } "if scope is not set in the topmost environment then public scope is assumed.  if scope is group, it assumes group_vars_set is set in the topmost environment. it returns properly formatted page title for the appropriate scope. depending on settings it may display the logo. if show_logo_p is 1, logo will be displayed (given that the logo is enabled for this page), else logo will not be displayed." {
    if { [uplevel [ad_scope_upvar_level] {info exists scope}] } {
	upvar [ad_scope_upvar_level] scope scope
    } else {
	set scope public
    }

    switch $scope {
	public {
	    return "<h2>$page_title</h2>"
	}
	group {
	    upvar [ad_scope_upvar_level] group_vars_set group_vars_set
	    set group_id [ns_set get $group_vars_set group_id]
	    set group_name [ns_set get $group_vars_set group_name]
	    return [ug_page_title $page_title $group_id $group_name $show_logo_p]
	}
	user {
	    # this may be later modified if we allow users to customize the display of their pages
	    return "<h2>$page_title</h2>"
	}
    }
}

proc_doc ad_scope_admin_page_title { page_title} "if scope is not set in the topmost environment then public scope is assumed.  if scope is group, it assumes group_vars_set is set in the topmost environment. it returns properly formatted admin page title for the appropriate scope." {
    if { [uplevel [ad_scope_upvar_level] {info exists scope}] } {
	upvar [ad_scope_upvar_level] scope scope
    } else {
	set scope public
    }

    switch $scope {
	public {
	    return "<h2>$page_title</h2>"
	}
	group {
	    upvar [ad_scope_upvar_level] group_vars_set group_vars_set
	    set group_id [ns_set get $group_vars_set group_id]
	    set group_name [ns_set get $group_vars_set group_name]
	    return [ug_admin_page_title $page_title $group_id $group_name]
	}
	user {
	    # this may be later modified if we allow users to customize the display of their pages
	    return "<h2>$page_title</h2>"
	}
    }
}

proc_doc ad_scope_page_top { window_title page_title {context_bar_title ""} } "ad_scope_page_top combines header, page title, context bar and horizontal line and generates a standard looking top of the page. window_title is the title that should appear in the browser window. page_title is the title that will be displayed on the page. context_bar_title is the title appearing as the last item in the context bar. if context_bar_title is empty or not provided then page_title will be used instead of context_bar_title. if scope is not set in the topmost environment then public scope is assumed.  if scope=group, it assumes that group_vars_set is set in the topmost environment." {
    set return_val "
    [ad_scope_header $window_title]
    [ad_scope_page_title $page_title]
    "
    append return_val "[ad_scope_context_bar_ws_or_index [ad_decode $context_bar_title "" $page_title $context_bar_title]]
    <hr>
    "

    return $return_val
}

proc_doc ad_scope_admin_page_top { window_title page_title {context_bar_title ""} } "ad_scope_admin_page_top combines admin header, admin page title, admin context bar and horizontal line and generates a standard looking admin top of the page. window_title is the title that should appear in the browser window. page_title is the title that will be displayed on the page. context_bar_title is the title appearing as the last item in the context bar. if context_bar_title is empty or not provided then page_title will be used instead of context_bar_title. if scope is not set in the topmost environment then public scope is assumed.  if scope=group, it assumes that group_vars_set is set in the topmost environment." {
    set return_val "
    [ad_scope_admin_header $window_title]
    [ad_scope_admin_page_title $page_title]
    "
    append return_val "[ad_scope_admin_context_bar [ad_decode $context_bar_title "" $page_title $context_bar_title]]
    <hr>
    "
    return $return_val
}

proc_doc ad_scope_return_complaint { exception_count exception_text } "if scope is not set in the topmost environment then public scope is assumed. if scope=group, it assumes that group_vars_set is set in the topmost environment. returns a page complaining about the user's input (as opposed to an error in our software, for which ad_scope_return_error is more appropriate). it works the same way as ad_return_complaint, except that it uses appropriate scope display settings." {
    if { [uplevel [ad_scope_upvar_level] {info exists scope}] } {
	upvar [ad_scope_upvar_level] scope scope
    } else {
	set scope public
    }

    switch $scope {
	public {
	    return [ad_return_complaint $exception_count $exception_text]
	}
	group {
	    upvar [ad_scope_upvar_level] group_vars_set group_vars_set
	    set group_id [ns_set get $group_vars_set group_id]
	    set group_name [ns_set get $group_vars_set group_name]
	    set group_admin_email [ns_set get $group_vars_set group_admin_email]
	    return [ug_return_complaint $exception_count $exception_text $group_id $group_name $group_admin_email]
	}
	user {
	    # this may be later modified if we allow users to customize the display of their pages
	    return [ad_return_complaint $exception_count $exception_text]
	}
    }
}

proc_doc ad_scope_return_warning { title explanation } "if scope is not set in the topmost environment then public scope is assumed. if scope=group, it assumes that group_vars_set is set in the topmost environment. returns warning message properly formatted for appropriate scope. this procedure is appropriate for messages like not authorized to access this page." {
    if { [uplevel [ad_scope_upvar_level] {info exists scope}] } {
	upvar [ad_scope_upvar_level] scope scope
    } else {
	set scope public
    }

    switch $scope {
	public {
	    return [ad_return_warning $title $explanation]
	}
	group {
	    upvar [ad_scope_upvar_level] group_vars_set group_vars_set
	    set group_id [ns_set get $group_vars_set group_id]
	    set group_name [ns_set get $group_vars_set group_name]
	    set group_admin_email [ns_set get $group_vars_set group_admin_email]
	    return [ug_return_warning $title $explanation $group_id $group_name $group_admin_email]
	}
	user {
	    # this may be later modified if we allow users to customize the display of their pages
	    return [ad_return_warning $title $explanation]
	}
    }
}

proc_doc ad_scope_return_error { title explanation } "if scope is not set in the topmost environment then public scope is assumed. if scope=group, it assumes that group_vars_set is set in the topmost environment. this function should be used if we want to indicate an error to the user, which was produced by bug in our code. it returns error message properly formatted for appropriate scope." {
    if { [uplevel [ad_scope_upvar_level] {info exists scope}] } {
	upvar [ad_scope_upvar_level] scope scope
    } else {
	set scope public
    }

    switch $scope {
	public {
	    return [ad_return_error $title $explanation]
	}
	group {
	    upvar [ad_scope_upvar_level] group_vars_set group_vars_set
	    set group_id [ns_set get $group_vars_set group_id]
	    set group_name [ns_set get $group_vars_set group_name]
	    set group_admin_email [ns_set get $group_vars_set group_admin_email]
	    return [ug_return_error $title $explanation $group_id $group_name $group_admin_email]
	}
	user {
	    # this may be later modified if we allow users to customize the display of their pages
	    return [ad_return_error $title $explanation]
	}
    }
}

# the arguments are lists ( [list URL anchor])
# except for the last one, which we expect to be just text
proc_doc ad_scope_context_bar args "if scope is not set in the topmost environment then public scope is assumed. if scope=group, it assumes that group_vars_set is set in the topmost environment. returns a Yahoo-style hierarchical contextbar for appropriate scope, each arg should be a list of URL and description.  The last arg should be just a plain description." {
    set choices [list]
    set all_args [list]
    
    if { [uplevel [ad_scope_upvar_level] {info exists scope}] } {
	upvar [ad_scope_upvar_level] scope scope
    } else {
	set scope public
    }

    switch $scope {
	public {
	    set all_args $args
	}
	group {
	    upvar [ad_scope_upvar_level] group_vars_set group_vars_set
	    set group_context_bar_list [ns_set get $group_vars_set group_context_bar_list]
	    eval "lappend all_args $group_context_bar_list"
	    foreach arg $args {
		lappend all_args $arg
	    }
	}
	user {
	    set all_args $args
	    # this may be later modified if we allow users to customize the display of their pages	    
	}
    }

    set index 0
    foreach arg $all_args {
	incr index
	if { $index == [llength $all_args] } {
	    lappend choices $arg
	} else {
	    lappend choices "<a href=\"[lindex $arg 0]\">[lindex $arg 1]</a>"
	}
    }
    return [join $choices " : "]
}

# a context bar, rooted at the workspace
proc_doc ad_scope_context_bar_ws args "if scope is not set in the topmost environment then public scope is assumed. if scope=group, it assumes that group_context_bar_list are set in the topmost environment. returns a Yahoo-style hierarchical contextbar for appropriate scope, starting with a link to workspace." {
    set choices [list "<a href=\"[ad_pvt_home]\">Your Workspace</a>"]
    set all_args [list]

    if { [uplevel [ad_scope_upvar_level] {info exists scope}] } {
	upvar [ad_scope_upvar_level] scope scope
    } else {
	set scope public
    }

    switch $scope {
	public {
	    set all_args $args
	}
	group {
	    upvar [ad_scope_upvar_level] group_vars_set group_vars_set
	    set group_context_bar_list [ns_set get $group_vars_set group_context_bar_list]
	    eval "lappend all_args $group_context_bar_list"
	    foreach arg $args {
		lappend all_args $arg
	    }
	}
	user {
	    # this may be later modified if we allow users to customize the display of their pages	    
	    set all_args $args
	}
    }

    set index 0
    foreach arg $all_args {
	incr index
	if { $index == [llength $all_args] } {
	    lappend choices $arg
	} else {
	    lappend choices "<a href=\"[lindex $arg 0]\">[lindex $arg 1]</a>"
	}
    }
    return [join $choices " : "]
}

# a context bar, rooted at the workspace or index, depending on whether
# user is logged in
proc_doc ad_scope_context_bar_ws_or_index args "if scope is not set in the topmost environment then public scope is assumed. if scope=group, it assumes that group_context_bar_list are set in the topmost environment. returns a Yahoo-style hierarchical contextbar for appropriate scope, starting with a link to either the workspace or /, depending on whether or not the user is logged in." {
    if { [ad_get_user_id] == 0 } {
	set choices [list "<a href=\"/\">[ad_system_name]</a>"] 
    } else {
	set choices [list "<a href=\"[ad_pvt_home]\">Your Workspace</a>"]
    }

    set all_args [list]

    if { [uplevel [ad_scope_upvar_level] {info exists scope}] } {
	upvar [ad_scope_upvar_level] scope scope
    } else {
	set scope public
    }

    switch $scope {
	public {
	    set all_args $args
	}
	group {
	    upvar [ad_scope_upvar_level] group_vars_set group_vars_set
	    set group_context_bar_list [ns_set get $group_vars_set group_context_bar_list]
	    eval "lappend all_args $group_context_bar_list"
	    foreach arg $args {
		lappend all_args $arg
	    }
	}
	user {
	    # this may be later modified if we allow users to customize the display of their pages	    
	    set all_args $args
	}
    }

    set index 0
    foreach arg $all_args {
	incr index
	if { $index == [llength $all_args] } {
	    lappend choices $arg
	} else {
	    lappend choices "<a href=\"[lindex $arg 0]\">[lindex $arg 1]</a>"
	}
    }
    return [join $choices " : "]
}

proc_doc ad_scope_admin_context_bar args "if scope is not set in the topmost environment then public scope is assumed. if scope=group, it assumes that ug_admin_context_bar_list are set in the topmost environment. returns a Yahoo-style hierarchical contextbar for appropriate scope, starting with links to workspace and admin home.  Suitable for use in pages underneath /admin." {
    set choices [list "<a href=\"[ad_pvt_home]\">Your Workspace</a>" "<a href=\"/admin/\">Admin Home</a>"]
    set all_args [list]

    if { [uplevel [ad_scope_upvar_level] {info exists scope}] } {
	upvar [ad_scope_upvar_level] scope scope
    } else {
	set scope public
    }

    switch $scope {
	public {
	    set all_args $args
	}
	group {
	    upvar [ad_scope_upvar_level] group_vars_set group_vars_set
	    set group_context_bar_list [ns_set get $group_vars_set group_context_bar_list]
	    eval "lappend all_args $group_context_bar_list"
	    foreach arg $args {
		lappend all_args $arg
	    }
	}
	user {
	    # this may be later modified if we allow users to customize the display of their pages	    
	    set all_args $args
	}
    }

    set index 0
    foreach arg $all_args {
	incr index
	if { $index == [llength $all_args] } {
	    lappend choices $arg
	} else {
	    lappend choices "<a href=\"[lindex $arg 0]\">[lindex $arg 1]</a>"
	}
    }
    return [join $choices " : "]
}

# the arguments are lists ( [list URL anchor])
# except for the last one, which we expect to be just text
proc_doc ad_scope_navbar args "if scope is not set in the topmost environment then public scope is assumed. if scope=group, it assumes that group_navbar_list is set in the topmost environment. produces navigation bar. notice that navigation bar is different than context bar, which exploits a tree structure. navbar will just display a list of nicely formatted links." {
    if { [uplevel [ad_scope_upvar_level] {info exists scope}] } {
	upvar [ad_scope_upvar_level] scope scope
    } else {
	set scope public
    }

    set all_args [list]
    switch $scope {
	public {
	    set all_args $args
	}
	group {
	    upvar [ad_scope_upvar_level] group_vars_set group_vars_set
	    set group_navbar_list [ns_set get $group_vars_set group_navbar_list]

	    eval "lappend all_args $group_navbar_list"
	    foreach arg $args {
		lappend all_args $arg
	    }
	}
	user {
	    set all_args $args
	    # this may be later modified if we allow users to customize the display of their pages	    
	}
    }

    return [eval "ad_navbar $all_args"]
}

