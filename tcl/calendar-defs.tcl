# $Id: calendar-defs.tcl,v 3.0.4.1 2000/05/16 11:53:22 carsten Exp $
# calendar-defs.tcl
#
# by philg@mit.edu late 1998
# 
# for the /calendar system documented at /doc/calendar.html 

proc calendar_system_owner {} {
    return [ad_parameter SystemOwner calendar [ad_system_owner]]
}

proc calendar_footer {} {
    return [ad_footer [calendar_system_owner]]
}


##################################################################
#
# interface to the ad-user-contributions-summary.tcl system

ns_share ad_user_contributions_summary_proc_list

if { ![info exists ad_user_contributions_summary_proc_list] || [util_search_list_of_lists $ad_user_contributions_summary_proc_list "/calendar postings" 0] == -1 } {
    lappend ad_user_contributions_summary_proc_list [list "Calendar Postings" calendar_user_contributions 0]
}

proc_doc calendar_user_contributions {db user_id purpose} {Returns list items, one for each calendar posting} {
    if { $purpose == "site_admin" } {
	set restriction_clause ""
    } else {
	set restriction_clause "\nand c.approved_p = 't'"
    }
    set db_sub [ns_db gethandle subquery]

    set selection [ns_db select $db "
    select c.calendar_id, c.title, c.approved_p, c.start_date, cc.scope, cc.group_id, ug.group_name, ug.short_name,
           decode(cc.scope, 'public', 1, 'group', 2, 'user', 3, 4) as scope_ordering
    from calendar c, calendar_categories cc, user_groups ug
    where c.creation_user = $user_id $restriction_clause
    and c.category_id= cc.category_id
    and cc.group_id=ug.group_id(+)
    order by scope_ordering, cc.group_id, c.start_date desc"]

    set items ""
    set last_group_id ""
    set item_counter 0
    while { [ns_db getrow $db $selection] } {
	set_variables_after_query
	
	switch $scope {
	    public {
		if { $item_counter==0 } {
		    append items "<h4>Public Calendar Postings</h4>"		    
		    set root_url "/calendar"
		    set admin_root_url "/calendar/admin"
		}
	    }
	    group {
		if { $last_group_id!=$group_id } {
		    append items "<h4>$group_name Calendar Postings</h4>"
		    
		    set sub_selection [ns_db 0or1row $db_sub "
		    select section_key
		    from content_sections
		    where scope='group' and group_id=$group_id
		    and module_key='calendar'"]
		    
		    if { [empty_string_p $selection] } {
			set root_url "/calendar"
			set admin_root_url "/calendar/admin"
		    } else {
			set_variables_after_subquery
			set root_url "[ug_url]/[ad_urlencode $short_name]/[ad_urlencode $section_key]"
			set admin_root_url "[ug_admin_url]/[ad_urlencode $short_name]/[ad_urlencode $section_key]"
			
		    }
		} 
	    } 
	}
		
	if { $purpose == "site_admin" } {
	    append items "<li>[util_AnsiDatetoPrettyDate $start_date]: <a href=\"$admin_root_url/item.tcl?[export_url_vars calendar_id]\">$title</a>\n"
	    if { $approved_p == "f" } {
		append items "&nbsp; <font color=red>not approved</font>"
	    }
	} else {
	    append items "<li>[util_AnsiDatetoPrettyDate $start_date]: <a href=\"$root_url/item.tcl?[export_url_vars calendar_id]\">$title</a>\n"
	}
	
	set last_group_id $group_id
	incr item_counter
    }

    ns_db releasehandle $db_sub

    if [empty_string_p $items] {
	return [list]
    } else {
	return [list 0 "Calendar Postings" "<ul>\n\n$items\n\n</ul>"]
    }
}




