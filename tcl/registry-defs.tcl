# $Id: registry-defs.tcl,v 3.0 2000/02/06 03:13:59 ron Exp $
#
# registry-defs.tcl
#
# by philg@mit.edu on July 4, 1999
#

util_report_library_entry

##################################################################
#
# interface to the ad-new-stuff.tcl system

ns_share ad_new_stuff_module_list

if { ![info exists ad_new_stuff_module_list] || [util_search_list_of_lists $ad_new_stuff_module_list "Stolen Equipment Registry" 0] == -1 } {
    lappend ad_new_stuff_module_list [list "Stolen Equipment Registry" registry_new_stuff]
}


proc_doc registry_new_stuff {db since_when only_from_new_users_p purpose} "Only produces a report for the site administrator; the assumption is that random users won't want to see stolen equipment reports." {
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
where posted > '$since_when'
and sr.user_id = ut.user_id
"
    set result_items ""
    set selection [ns_db select $db $query]
    while { [ns_db getrow $db $selection] } {
	set_variables_after_query
	append result_items "<li><a href=\"/admin/registry/one-case.tcl?[export_url_vars stolen_id]\">$manufacturer $model</a> (from $email)"
    }
    if { ![empty_string_p $result_items] } {
	return "<ul>\n\n$result_items\n</ul>\n"
    } else {
	return ""
    }
}

util_report_successful_library_load
