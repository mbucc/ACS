# $Id: neighbor-defs.tcl,v 3.0.4.2 2000/04/28 15:08:18 carsten Exp $
# 
# neighbor-defs.tcl 
#
# by philg@mit.edu in 1996 or so
# 
# modified November 1, 1999 by philg to interface to 
# ad-user-contributions-summary.tcl system

# definitions for the neighbor-to-neighbor service (like a discussion
# forum but more layers of structure and intended for long-term
# storage of stories )

util_report_library_entry

proc neighbor_db_gethandle {} {
    if [catch {set db [ns_db gethandle]} errmsg] {
    # something wrong with the NaviServer/db connection
	ad_notify_host_administrator "please fix [ns_conn location]" "please fix the neighbor to neighbor service
at [ns_conn location] so that it can connect to the database

Thanks,

The Ghost of the NaviServer

Note:  this message was automatically sent by a Tcl CATCH statement running
inside [ns_conn location]
"
        return ""
    } else {
        return $db
    }
}

proc neighbor_header {title} {
    return [ad_header $title]
}

proc neighbor_footer {{signatory ""}} {
    return [ad_footer $signatory]
}

proc neighbor_system_name {} {
    set custom_name [ad_parameter SystemName neighbor]
    if ![empty_string_p $custom_name] {
	return $custom_name 
    } else {
	return "[ad_parameter SystemName] Neighbor to Neighbor"
    }
}

proc neighbor_uplink {} {
    if [ad_parameter OnlyOnePrimaryCategoryP neighbor 0] {
	return [ad_site_home_link]
    } else {
	return "<a href=\"index.tcl\">[neighbor_system_name]</a>"
    }
}

proc neighbor_home_link {category_id primary_category} {
    if { [ad_parameter OnlyOnePrimaryCategoryP neighbor 0] && ![empty_string_p [ad_parameter DefaultPrimaryCategory neighbor]] } {
	return "<a href=\"opc.tcl?category_id=$category_id\">[neighbor_system_name]</a>"
    } else {
	return "<a href=\"opc.tcl?category_id=$category_id\">$primary_category</a>"
    }
}

proc neighbor_system_owner {} {
    set custom_owner [ad_parameter SystemOwner neighbor]
    if ![empty_string_p $custom_owner] {
	return $custom_owner
    } else {
	return [ad_system_owner]
    }
}

# for opc.tcl

proc_doc neighbor_summary_items_approved {category_id} "returns list of Tcl lists; each list contains a subcategory ID, subcategory_1 name and a count; we expect this to be memoized" {
    set db [ns_db gethandle subquery]
    set selection [ns_db select $db "select sc.subcategory_id, sc.subcategory_1, count(n.neighbor_to_neighbor_id) as count
from neighbor_to_neighbor n, n_to_n_subcategories sc
where n.category_id  = $category_id
and n.subcategory_id = sc.subcategory_id
and n.approved_p='t'
group by sc.subcategory_id, sc.subcategory_1
order by sc.subcategory_1"]
    set return_list [list]
    while {[ns_db getrow $db $selection]} {
	set_variables_after_query
	lappend return_list [list $subcategory_id $subcategory_1 $count]
    }
    ns_db releasehandle $db
    return $return_list
}


##################################################################
#
# interface to the ad-new-stuff.tcl system

ns_share ad_new_stuff_module_list

if { ![info exists ad_new_stuff_module_list] || [util_search_list_of_lists $ad_new_stuff_module_list [neighbor_system_name] 0] == -1 } {
    lappend ad_new_stuff_module_list [list [neighbor_system_name] neighbor_new_stuff]
}

proc neighbor_new_stuff {db since_when only_from_new_users_p purpose} {
    if { $only_from_new_users_p == "t" } {
	set users_table "users_new"
    } else {
	set users_table "users"
    }
    set query "select nn.neighbor_to_neighbor_id, nn.about, nn.title, ut.first_names, ut.last_name, ut.email
from neighbor_to_neighbor nn, $users_table ut
where posted > '$since_when'
and nn.poster_user_id = ut.user_id
order by posted desc"
    set result_items ""
    set selection [ns_db select $db $query]
    while { [ns_db getrow $db $selection] } {
	set_variables_after_query
	switch $purpose {
	    web_display {
		append result_items "<li><a href=\"/neighbor/view-one.tcl?[export_url_vars neighbor_to_neighbor_id]\">$about : $title</a> -- $first_names $last_name \n" }
	    site_admin { 
		append result_items "<li><a href=\"/admin/neighbor/view-one.tcl?[export_url_vars neighbor_to_neighbor_id]\">$about : $title</a> -- $first_names $last_name ($email) \n"
	    }
	    email_summary {
		append result_items "A story about $about from $first_names $last_name titled 
\"$title\"
  -- [ad_url]/neighbor/view-one.tcl?[export_url_vars neighbor_to_neighbor_id]

"
            }
	}
    }
    # we have the result_items or not
    if { $purpose == "email_summary" } {
	return $result_items
    } elseif { ![empty_string_p $result_items] } {
	return "<ul>\n\n$result_items\n</ul>\n"
    } else {
	return ""
    }
}


##################################################################
#
# interface to the ad-user-contributions-summary.tcl system

ns_share ad_user_contributions_summary_proc_list

if { ![info exists ad_user_contributions_summary_proc_list] || [util_search_list_of_lists $ad_user_contributions_summary_proc_list "Neighbor to Neighbor" 0] == -1 } {
    lappend ad_user_contributions_summary_proc_list [list "Neighbor to Neighbor" neighbor_user_contributions 0]
}

proc_doc neighbor_user_contributions {db user_id purpose} {Returns list items, one for each posting} {
    if { $purpose == "site_admin" } {
	set target_url "/admin/neighbor/view-one.tcl"
	set restriction_clause ""
    } else {
	set target_url "/neighbor/view-one.tcl"
	set restriction_clause "\nand neighbor_to_neighbor.approved_p = 't'"
    }
    set selection [ns_db select $db "select neighbor_to_neighbor_id, about, title, approved_p, to_char(posted,'Month dd, yyyy') as posted
from neighbor_to_neighbor
where poster_user_id = $user_id $restriction_clause
order by neighbor_to_neighbor_id"]

    set neighbor_items ""
    while {[ns_db getrow $db $selection]} {
	set_variables_after_query
	append neighbor_items "<li>$posted: <A HREF=\"$target_url?[export_url_vars neighbor_to_neighbor_id]\">$about : $title</a>\n"
	if { $approved_p == "f" } {
	    append neighbor_items "<font color=red>unapproved</font>\n"
	}
    }
    if [empty_string_p $neighbor_items] {
	return [list]
    } else {
	return [list 1 "Neighbor to Neighbor" "<ul>\n\n$neighbor_items\n\n</ul>"]
    }
}


### legacy redirects

ns_register_proc GET /classified/NtoNPostNewStage1 ad_returnredirect http://db.photo.net/neighbor/
ns_register_proc POST /classified/NtoNPostNewStage2 ad_returnredirect http://db.photo.net/neighbor/
ns_register_proc POST /classified/EnterUpdateNtoN ad_returnredirect http://db.photo.net/neighbor/
ns_register_proc GET /classified/WelcomeToPhotoNetNeighbor_To_Neighbor ad_returnredirect http://db.photo.net/neighbor/
ns_register_proc GET /classified/NtoN  ad_returnredirect http://db.photo.net/neighbor/
ns_register_proc GET /classified/ViewNtoNByDate ad_returnredirect http://db.photo.net/neighbor/
ns_register_proc GET /classified/ViewNtoNByAbout ad_returnredirect http://db.photo.net/neighbor/
ns_register_proc GET /classified/ViewNtoNInOneCategory ad_returnredirect http://db.photo.net/neighbor/
ns_register_proc POST /classified/ViewNtoNInOneCategory ad_returnredirect http://db.photo.net/neighbor/
ns_register_proc GET /classified/ViewOneNtoN  ad_returnredirect http://db.photo.net/neighbor/
ns_register_proc GET /classified/NtoNSearchForm  ad_returnredirect http://db.photo.net/neighbor/
ns_register_proc POST /classified/ViewNtoNFullTextSearch  ad_returnredirect http://db.photo.net/neighbor/

ns_register_proc POST /classified/ModifyNtoNFirstMenu  ad_returnredirect http://db.photo.net/neighbor/
ns_register_proc GET /classified/ModifyNtoNChallenge ad_returnredirect http://db.photo.net/neighbor/
ns_register_proc POST /classified/ModifyNtoNPostChallenge  ad_returnredirect http://db.photo.net/neighbor/

util_report_successful_library_load
