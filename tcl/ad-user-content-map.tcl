# $Id: ad-user-content-map.tcl,v 3.1 2000/02/26 12:55:27 jsalz Exp $
# ad-user-content-map.tcl
#
# by philg@mit.edu in anicent (1998) times
#
# enhanced on November 1, 1999 to participate in ad-user-contributions-summary.tcl
# system
# 

# this filter runs after thread has finished serving an HTML page to a 
# user.  It does the following

#     a. grabs a db conn if one is immediately available
#         (does nothing if all the conns are in use)
#     b. checks to see if there is a user_id cookie
#     c. checks in db to see if user has already read this page
#     d. if not, does a db insert

util_report_library_entry

proc ad_maintain_user_content_map {conn args why} {
    # no security check, just look at header
    set user_id [ad_get_user_id]
    if { $user_id != 0 } {
	# this is a registered user
	if { [catch { set db [ns_db gethandle -timeout -1]  } errmsg] || [empty_string_p $db] } {
	    # the non-blocking call to gethandle raised a Tcl error; this
	    # means a db conn isn't free right this moment, so let's just
	    # return
	    ns_log Notice "Db handle wasn't available in ad_maintain_user_content_map"
	    return filter_ok
	} else {
	    # we have $db
	    # let's figure out which page_id corresponds to the URL 
	    # we're looking at
	    set selection [ns_db 0or1row $db "select page_id from static_pages where url_stub = '[DoubleApos [ns_conn url]]'"]
	    # the row might not be in the database
	    if { ![empty_string_p $selection] && ![empty_string_p [ns_set get $selection page_id]] } {
		set_variables_after_query
		# we found the page, probably would be best to put the next
		# couple of things into a PL/SQL proc
		set n_rows [database_to_tcl_string $db "select count(*) from user_content_map where page_id = $page_id and user_id = $user_id"]
		if { $n_rows == 0 } {
		    # we have a user_id, a page_id, and we know that 
		    # this map is not yet recorded		  
		    ns_db dml $db "insert into user_content_map (user_id, page_id, view_time) values ($user_id, $page_id, sysdate)"
		}
	    }
	}
    }
    return filter_ok
}


ns_share -init { set ad_user_content_map_filters_installed_p 0 } ad_user_content_map_filters_installed_p

if { !$ad_user_content_map_filters_installed_p } {
    set ad_user_content_map_filters_installed_p 1
    ns_log Notice "ad-user-content-map.tcl registering ad_maintain_user_content_map as a trace filter on *.htm*"
    ad_register_filter trace GET *.htm* ad_maintain_user_content_map
}

ns_share ad_user_contributions_summary_proc_list

if { ![info exists ad_user_contributions_summary_proc_list] || [util_search_list_of_lists $ad_user_contributions_summary_proc_list "Static pages viewed when logged in" 0] == -1 } {
    lappend ad_user_contributions_summary_proc_list [list "Static pages viewed when logged in" ad_static_page_views_user_contributions 5]
}

proc_doc ad_static_page_views_user_contributions {db user_id purpose} {Returns empty list if purpose is not "site_admin".  Otherwise a triplet of all the static pages viewed while this user was logged in.} {
    if { $purpose != "site_admin" } {
	return [list]
    }
    set selection [ns_db select $db "select user_content_map.view_time, static_pages.page_id, static_pages.page_title, static_pages.url_stub
from user_content_map, static_pages
where user_content_map.page_id = static_pages.page_id
and user_content_map.user_id = $user_id
order by view_time asc"]
    set items ""
    while {[ns_db getrow $db $selection]} {
	set_variables_after_query
	append items "<li>[util_AnsiDatetoPrettyDate $view_time]:  <A HREF=\"/admin/static/page-summary.tcl?page_id=$page_id\">$url_stub</a> ($page_title)\n"
    }
    if [empty_string_p $items] {
	return [list]
    } else {
	return [list 5 "Static pages viewed when logged in" "<ul>\n\n$items\n\n</ul>"]
    }
}


util_report_successful_library_load
