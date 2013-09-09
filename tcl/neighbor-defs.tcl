# /tcl/neighbor-defs.tcl

ad_library {

    Procedure definitions for the neighbor-to-neighbor module.

    @creation-date 1 Jan 1996
    @author Philip Greenspun (philg@mit.edu)
    @cvs-id $id$

}

# removed neighbor_db_gethandle since explicit handle management is no longer necessary

ad_proc neighbor_header {
    title
} {
    Returns a header for the neighbor-to-neighbor pages.

    @author Philip Greenspun (philg@mit.edu)
    @param title the title of the page to put into the header.
    @return the page header.
    @error if the title is not specified.

} {
    return [ad_header $title]
}

ad_proc neighbor_footer {
    {signatory ""}
} {
    Returns a footer for the neighbor-to-neighbor pages.

    @author Philip Greenspun (philg@mit.edu)
    @param signatory the person signing the page.
    @return the page footer.
} {
    return [ad_footer $signatory]
}

ad_proc neighbor_system_name {} {
    Returns the name specified for the neighbor-to-neighbor system in the parameters files.

    @author Philip Greenspun (philg@mit.edu)
    @return the custom name for the neighbor-to-neighbor system if it is set, or the system name with "Neighbor to Neighbor" appended to it.
} {
    set custom_name [ad_parameter SystemName neighbor]
    if ![empty_string_p $custom_name] {
	return $custom_name 
    } else {
	return "[ad_parameter SystemName] Neighbor to Neighbor"
    }
}

ad_proc neighbor_uplink {} {
    Returns a link to the top of the neighbor-to-neighbor system.

    @author Philip Greenspun (philg@mit.edu)
    @return an HTML link to the top of the neighbor-to-neighbor system.
} {
    if [ad_parameter OnlyOnePrimaryCategoryP neighbor 0] {
	return [ad_site_home_link]
    } else {
	return "<a href=\"index\">[neighbor_system_name]</a>"
    }
}

ad_proc neighbor_home_link {
    category_id primary_category
} {
    Returns a link to the primary category in the neighbor-to-neighbor system.

    @author Philip Greenspun (philg@mit.edu)
    @param category_id id of the primary category.
    @param primary_category name of the primary category.
    @return an HTML link to the primary category.
    @error if category_id or primary_category is not specified.
} {
    if { [ad_parameter OnlyOnePrimaryCategoryP neighbor 0] && ![empty_string_p [ad_parameter DefaultPrimaryCategory neighbor]] } {
	return "<a href=\"opc?category_id=$category_id\">[neighbor_system_name]</a>"
    } else {
	return "<a href=\"opc?category_id=$category_id\">$primary_category</a>"
    }
}

ad_proc neighbor_system_owner {} {
    Returns the name of the owner of the neighbor-to-neighbor system.

    @author Philip Greenspun (philg@mit.edu)
    @return the name of the neighbor-to-neighbor system owner if specified, or the name of the site owner.
} {
    set custom_owner [ad_parameter SystemOwner neighbor]
    if ![empty_string_p $custom_owner] {
	return $custom_owner
    } else {
	return [ad_system_owner]
    }
}

# for opc.tcl

ad_proc neighbor_summary_items_approved {
    category_id
} { 
    Returns list of Tcl lists of approved postings.  Each list contains a subcategory ID, subcategory_1 name and a count.  We expect this to be memoized.

    @author Philip Greenspun (philg@mit.edu)
    @param category_id id of the category to list.
    @return a list of lists with subcategory id, subcategory_1 name and count.
    @error if category_id is not specified.
} {
    set sql_query "select sc.subcategory_id, sc.subcategory_1, count(n.neighbor_to_neighbor_id) as count
from neighbor_to_neighbor n, n_to_n_subcategories sc
where n.category_id  = :category_id
and n.subcategory_id = sc.subcategory_id
and n.approved_p='t'
group by sc.subcategory_id, sc.subcategory_1
order by sc.subcategory_1"
    set return_list [list]
    db_foreach neighbor_approved_items $sql_query {
	lappend return_list [list $subcategory_id $subcategory_1 $count]
    }
    db_release_unused_handles
    return $return_list
}

##################################################################
#
# interface to the ad-new-stuff.tcl system

ns_share ad_new_stuff_module_list

if { ![info exists ad_new_stuff_module_list] || [util_search_list_of_lists $ad_new_stuff_module_list [neighbor_system_name] 0] == -1 } {
    lappend ad_new_stuff_module_list [list [neighbor_system_name] neighbor_new_stuff]
}

ad_proc neighbor_new_stuff {
    since_when only_from_new_users_p purpose
} {
    Return a list of new items in the neighbor-to-neighbor system.

    @author Philip Greenspun (philg@mit.edu)
    @params since_when only show stuff posted after this date.
    @params only_from_new_users_p only show stuff posted by new users.
    @params purpose specifies whether the data returned will be used for web display, site admin, or e-mail summary, so it can be formatted properly.
    @return a list (possibly HTML formatted) of new items posted in the neighbor-to-neighbor system.
    @error if since_when, only_from_new_users_p, or purpose are not specified.
} {
    if { $only_from_new_users_p == "t" } {
	set users_table "users_new"
    } else {
	set users_table "users"
    }
    set sql_query "select nn.neighbor_to_neighbor_id, nn.about, nn.title, ut.first_names, ut.last_name, ut.email
from neighbor_to_neighbor nn, [db_quote_name $users_table] ut
where posted > :since_when
and nn.poster_user_id = ut.user_id
order by posted desc"
    set result_items ""
    db_foreach neighbor_new_items $sql_query {
	switch $purpose {
	    web_display {
		append result_items "<li><a href=\"/neighbor/view-one?[export_url_vars neighbor_to_neighbor_id]\">$about : $title</a> -- $first_names $last_name \n" }
	    site_admin { 
		append result_items "<li><a href=\"/admin/neighbor/view-one?[export_url_vars neighbor_to_neighbor_id]\">$about : $title</a> -- $first_names $last_name ($email) \n"
	    }
	    email_summary {
		append result_items "A story about $about from $first_names $last_name titled 
\"$title\"
  -- [ad_url]/neighbor/view-one.tcl?[export_url_vars neighbor_to_neighbor_id]

"
            }
	}
    }

    db_release_unused_handles
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

ad_proc neighbor_user_contributions {
    user_id purpose
} {
    Returns list items, one for each posting by a given user.
    
    @author Philip Greenspun (philg@mit.edu)
    @params user_id the user id of the person whose posts you want to view.
    @params purpose purpose of the request, so links can point to the user pages or the admin pages.
    @return an HTML formatted list of postings, or an empty list if there are no postings.
    @error is user_id or purpose are not specified.
} {
    set sql_query "select neighbor_to_neighbor_id, about, title, approved_p, to_char(posted,'Month dd, yyyy') as posted
from neighbor_to_neighbor
where poster_user_id = :user_id"

    if { $purpose == "site_admin" } {
	set target_url "/admin/neighbor/view-one.tcl"
    } else {
	set target_url "/neighbor/view-one.tcl"
	append sql_query "\nand neighbor_to_neighbor.approved_p = 't'"
    }
    append sql_query "\norder by neighbor_to_neighbor_id"

    set neighbor_items ""
    db_foreach neighbor_user_postings $sql_query {
	append neighbor_items "<li>$posted: <A HREF=\"$target_url?[export_url_vars neighbor_to_neighbor_id]\">$about : $title</a>\n"
	if { $approved_p == "f" } {
	    append neighbor_items "<font color=red>unapproved</font>\n"
	}
    }

    db_release_unused_handles
    if [empty_string_p $neighbor_items] {
	return [list]
    } else {
	return [list 1 "Neighbor to Neighbor" "<ul>\n\n$neighbor_items\n\n</ul>"]
    }
}



