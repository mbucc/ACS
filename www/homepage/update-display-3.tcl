# $Id: update-display-3.tcl,v 3.0.4.1 2000/04/28 15:11:04 carsten Exp $
set_the_usual_form_variables
# filesystem_node

# First, we need to get the user_id
set user_id [ad_verify_and_get_user_id]

# If the user is not registered, we need to redirect him for
# registration
if { $user_id == 0 } {
    ad_redirect_for_registration
    return
}

set db [ns_db gethandle]

append update_sql "
update users_homepages
set 	bgcolor			        = null,
	textcolor			= null,
	unvisited_link	  		= null,
	visited_link	  		= null,
	link_text_decoration  		= null,
	link_font_weight		= null,
	font_type		  	= null,
	maint_bgcolor	 		= null,
	maint_textcolor			= null,
	maint_unvisited_link		= null,
	maint_visited_link	  	= null,
	maint_link_text_decoration  	= null,
	maint_link_font_weight		= null,
	maint_font_type			= null
where user_id=$user_id
"

ns_db dml $db $update_sql

ns_db releasehandle $db

ad_returnredirect "index.tcl?filesystem_node=$filesystem_node"








