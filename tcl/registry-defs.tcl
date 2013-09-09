# tcl/registry-defs.tcl

ad_library {
    @author philg@mit.edu
    @creation-date July 4, 1999
    @cvs-id registry-defs.tcl,v 3.2.2.2 2000/07/22 23:21:44 bquinn Exp
}

##################################################################
#
# interface to the ad-new-stuff.tcl system

ns_share ad_new_stuff_module_list

if { ![info exists ad_new_stuff_module_list] || [util_search_list_of_lists $ad_new_stuff_module_list "Stolen Equipment Registry" 0] == -1 } {
    lappend ad_new_stuff_module_list [list "Stolen Equipment Registry" registry_new_stuff]
}

proc_doc registry_new_stuff {since_when only_from_new_users_p purpose} "Only produces a report for the site administrator; the assumption is that random users won't want to see stolen equipment reports." {
    if { $purpose != "site_admin" } {
	return ""
    }
    if { $only_from_new_users_p == "t" } {
	set users_table "users_new"
    } else {
	set users_table "users"
    }
    set query "select sr.stolen_id, sr.manufacturer, sr.model, ut.email
               from stolen_registry sr, $users_table ut
               where posted > :since_when
               and sr.user_id = ut.user_id
    "
    set result_items ""
    db_foreach report $query -bind [ad_tcl_vars_to_ns_set since_when] {
	append result_items "<li><a href=\"/admin/registry/one-case?[export_url_vars stolen_id]\">$manufacturer $model</a> (from $email)"
    }
    if { ![empty_string_p $result_items] } {
	return "<ul>\n\n$result_items\n</ul>\n"
    } else {
	return ""
    }
}

