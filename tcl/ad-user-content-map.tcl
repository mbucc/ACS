# /tcl/ad-user-content-map.tcl

ad_library {
    Enhanced on November 1, 1999 to participate in ad-user-contributions-summary.tcl
    system.

    @creation-date 1998
    @author philg@mit.edu
    @cvs-id ad-user-content-map.tcl,v 3.7.2.5 2000/07/25 08:54:04 avni Exp
}

ad_proc ad_path_relative {path} {
    
    Returns the component of path relative to [acs_root_dir]/www.
    If path does not begin with [acs_root_dir]/www it is returned
    unchanged. 

} {
    set root "[acs_root_dir]/www"

    # verify that path starts with $root
    if { [string first $root $path] == 0 } {
	# it does, so trim out the leading part
	set path [string range $path [expr { [string length $root]}] end]
    }

    return $path
}


ad_proc ad_maintain_user_content_map_filter {conn args why} {

    this filter runs after thread has finished serving an HTML page to a 
    user.  It does the following

    a. grabs a db conn if one is immediately available
       (does nothing if all the conns are in use)
    b. checks to see if there is a user_id cookie
    c. checks in db to see if user has already read this page
    d. if not, does a db insert

} {

    set url [ad_conn canonical_url]
    if { [empty_string_p $url] } {
	set url [ns_conn url]
    }

    ad_maintain_user_content_map $url
    return filter_ok
}



ad_proc ad_maintain_user_content_map {url} "" {
    set url [ad_path_relative [ad_conn file]]
    ns_log Notice "ad_maintain_user_content_map: trying to log hit for $url extension"

    # no security check, just look at header
    set user_id [ad_get_user_id]
    if { $user_id != 0 } {
	# this is a registered user, and we already have a database connection

	# let's figure out which page_id corresponds to the URL 
	# we're looking at
	
	if { ![db_0or1row  page_id_lookup {
	    select page_id from static_pages where url_stub = :url
	}]} {
	    ns_log Notice "ad_maintain_user_content_map: Couldn't find page $url in database!"
	} else {	    

	    # we found the page, probably would be best to put the next
	    # couple of things into a PL/SQL proc

	    set n_rows [db_string ad_user_content_map_maintain_user_content_rows "
	    select count(*) 
	    from   user_content_map 
	    where  page_id = :page_id 
	    and    user_id = :user_id"]

	    if { $n_rows == 0 } {
		# we have a user_id, a page_id, and we know that this
		# map is not yet recorded		    

		db_dml user_content_map_update {
		    insert into user_content_map 
		    (user_id, 
		     page_id, 
		     view_time) 
		    values 
		    (:user_id, 
		     :page_id, 
		      sysdate)
		}
	    }
	}
    }
}


ns_share -init { set ad_user_content_map_filters_installed_p 0 } ad_user_content_map_filters_installed_p

if { !$ad_user_content_map_filters_installed_p } {
    set ad_user_content_map_filters_installed_p 1
    ns_log Notice "ad-user-content-map.tcl registering ad_maintain_user_content_map_filter as a trace filter on *.htm*"
    ad_register_filter trace GET *.htm* ad_maintain_user_content_map_filter
}

ns_share ad_user_contributions_summary_proc_list

if { ![info exists ad_user_contributions_summary_proc_list] || [util_search_list_of_lists $ad_user_contributions_summary_proc_list "Static pages viewed when logged in" 0] == -1 } {
    lappend ad_user_contributions_summary_proc_list [list "Static pages viewed when logged in" ad_static_page_views_user_contributions 5]
}

ad_proc ad_static_page_views_user_contributions {user_id purpose} {
    Returns empty list if purpose is not "site_admin".  
    Otherwise a triplet of all the static pages viewed while this user was logged in.
} {
    if { $purpose != "site_admin" } {
	return [list]
    }

    set items ""

    db_foreach ad_user_content_map_ad_maintain_user_content_map_ad_static_page_views_useer_contributions_user_view {
	select user_content_map.view_time, 
	       static_pages.page_id, 
               static_pages.page_title, 
               static_pages.url_stub
        from   user_content_map, static_pages
        where  user_content_map.page_id = static_pages.page_id
        and    user_content_map.user_id = :user_id
        order by view_time asc
    } {
	append items "<li>[util_AnsiDatetoPrettyDate $view_time]:  <A HREF=\"/admin/static/page-summary?page_id=$page_id\">$url_stub</a> ($page_title)\n"
    }

    if [empty_string_p $items] {
	return [list]
    } else {
	return [list 5 "Static pages viewed when logged in" "<ul>\n\n$items\n\n</ul>"]
    }
}
