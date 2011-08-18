# $Id: bookmarks-defs.tcl,v 3.1.2.1 2000/04/28 15:08:16 carsten Exp $
# bookmarks-defs.tcl
#
# by aure@arsdigita.com and dh@arsdigita.com, July 1999
# 
# procedures for the bookmarks system
# documented at /doc/bookmarks.html

util_report_library_entry


proc bm_system_owner {} {
    return [ad_parameter SystemOwner bm [ad_system_owner]]
}

proc bm_footer {} {
    return [ad_footer [bm_system_owner]]
}

proc_doc bm_folder_selection {db owner_id bookmark_id } { Creates an option list of all the folders a selected object may move to - the resulting <select> name is 'parent_id'.} {
    set folder_exclusion_clauses [list "owner_id = $owner_id" "folder_p = 't'"]

    set selection [ns_db 0or1row $db "select folder_p, parent_id, parent_sort_key, local_sort_key from bm_list where bookmark_id = $bookmark_id"]
    
    if { $selection != "" } {
	set_variables_after_query

	if { $folder_p == "t" } {
	    # We cannot move folders to be their own children.
	    lappend folder_exclusion_clauses "(parent_sort_key not like '$parent_sort_key$local_sort_key%' or parent_sort_key is null)"
	    lappend folder_exclusion_clauses "bookmark_id <> $bookmark_id"
	}
    } else {
	set parent_id ""
    }
	
    set selection [ns_db select $db "select bookmark_id, local_title, lpad(' ', 6*(nvl(length(parent_sort_key),0)+3), '&nbsp;') as indentation
from bm_list
where [join $folder_exclusion_clauses " and "]
order by parent_sort_key || local_sort_key"]

    if { $parent_id == "" } {
	set edit_form_option "<option value=\"\" selected>Top Level</option>\n"
    } else {
	set edit_form_option "<option value=\"\" > Top Level </option>\n"
    }

    set folder_count 0
    while {[ns_db getrow $db $selection]} {
	set_variables_after_query
	incr folder_count
	
	if { $bookmark_id == $parent_id } {
	    append edit_form_option "<option value=$bookmark_id selected>$indentation $local_title </option>\n"
	} else {
	    append edit_form_option "<option value=$bookmark_id>$indentation $local_title</option>\n"
	}
	
    }
    if {$folder_count > 8} { 
	set size_count 8
    } else {
	set size_count [expr $folder_count + 1]
    }
    return "<select size=$size_count name=parent_id>$edit_form_option</select>"
}

proc_doc bm_set_hidden_p {db owner_id } {This procedure insures that the 'hidden_p' column in the 'bm_list' table is consistant with the privacy of the folder structure (ie a bookmark inside a private folder or in a folder in a private folder etc is considered to be hidden_p=t) } {

    # get the bad parents
    set sql_get_bad "
        select  bookmark_id
        from    bm_list
        where   owner_id = $owner_id
        and     private_p = 't'"

    set bad_parents [database_to_tcl_list $db $sql_get_bad]
    set bad_parents [join $bad_parents ","]

    # this could be trouble if the bad_parents list is too long 
    if { ![empty_string_p $bad_parents] } {
	# get all the 'bookmark_id's which should be public
	set sql_get_new_public "
	    select  bookmark_id
    	    from    bm_list 
	    where   owner_id = $owner_id
	    and     private_p <> 't'
	    connect by  prior bookmark_id = parent_id
	    and parent_id  not in ($bad_parents)
	    start with parent_id is NULL"

	set not_hidden_list  [database_to_tcl_list $db $sql_get_new_public]
	

	# set _all_ 'bookmark_id's hidden_p='t' then set the 'bookmarks_id's in not_hidden_list to hidden_p='f'
	ns_db dml $db "
	    update  bm_list
	    set     hidden_p = 't'
	    where   owner_id = $owner_id "
	foreach bookmark_id $not_hidden_list {
	    ns_db dml $db "
	        update bm_list
	        set    hidden_p = 'f'
	        where  bookmark_id = $bookmark_id
	        and    owner_id = $owner_id" 
	}
    } else {
	ns_db dml $db "
	    update bm_list
	    set    hidden_p = 'f'
	    where  owner_id = $owner_id"
    }
}

proc_doc bm_set_in_closed_p {db owner_id } {This procedure insures that the 'in_closed_p' column in the 'bm_list' table is consistant with the open/closed of the folder structure (ie a bookmark inside a closed folder or in a folder in a closed folder etc is considered to be in_closed_p=t) } {
    ns_db dml $db "begin transaction"
    
    # Set all files to be open.
    ns_db dml $db "update bm_list set in_closed_p = 'f' where owner_id = $owner_id"

    # Set as in_closed_p those bookmarks which have any parent as closed.
    ns_db dml $db "update bm_list set in_closed_p = 't' 
 where bookmark_id in (select bookmark_id from bm_list
 where owner_id = $owner_id
 connect by prior bookmark_id = parent_id
 start with parent_id in (select bookmark_id from bm_list where owner_id = $owner_id and folder_p = 't' and closed_p = 't'))"

    ns_db dml $db "end transaction"
}

# you need to register this (rather than using a .tcl page)
# so that people can view exported bookmarks,
# click "Save As" and be supplied with the correct filename by default

ns_register_proc GET /bookmarks/bookmark.htm bm_export_to_netscape

proc_doc bm_export_to_netscape {} {Outputs a set of bookmarks in the standard Netscape bookmark.htm format} {

    set user_id [ad_verify_and_get_user_id]

    # redirect some one who hasn't logged on to the server front page
    if { $user_id == 0} {
	ad_returnredirect "/register/index.tcl?return_url=[ns_urlencode [ns_conn url]]"
    }
    set db [ns_db gethandle subquery]

    set sql_query "
        select first_names||' '||last_name as name 
        from   users 
        where  user_id=$user_id"
    set name [database_to_tcl_string $db $sql_query]

    set sql_query "
        select   bookmark_id, bm_list.url_id, 
                 local_title, creation_date, parent_id
                 parent_id, complete_url, folder_p,
                 parent_sort_key||local_sort_key as sort_key
        from     bm_list, bm_urls
        where    owner_id=$user_id
        and      bm_list.url_id=bm_urls.url_id(+)
        order by sort_key"

    set selection [ns_db select $db $sql_query]

    set folder_list 0

    while {[ns_db getrow $db $selection]} {
	set_variables_after_query

	set previous_parent_id [lindex $folder_list [expr [llength $folder_list]-1]]
	
	if {$parent_id!=$previous_parent_id} {

	    set parent_location [lsearch -exact $folder_list $parent_id]
	    
	    if {$parent_location==-1} {
		lappend folder_list $parent_id
		append bookmark_html "<DL><p>\n\n"
	    } else { 	    
		set drop [expr [llength $folder_list]-$parent_location]
		set folder_list [lrange $folder_list 0 $parent_location]
		for {set i 1} {$i<$drop} {incr i} {
		    append bookmark_html "</DL><p>\n\n"
		}
	    }
	}

	if {$folder_p=="t"} {
	    append bookmark_html "<DT><H3 ADD_DATE=\"[ns_time]\">$local_title</H3>\n\n"
	} else {
	    append bookmark_html "<DT><A HREF=\"$complete_url\" ADD_DATE=\"[ns_time]\" LAST_VISIT=\"0\" LAST_MODIFIED=\"0\">$local_title</A>\n\n"
	}
	
    }

    set html "<!DOCTYPE NETSCAPE-Bookmark-file-1>

<!-- This is an automatically generated file.

It will be read and overwritten.

Do Not Edit! -->

<TITLE>Bookmarks for $name</TITLE>

<H1>Bookmarks for $name</H1>


<DL><p>

$bookmark_html

</DL><p>
"

    ns_db releasehandle $db
    ns_return 200 text/html $html
    
}


proc_doc bm_host_url {complete_url} {Takes a URL and returns the host portion of it (i.e., http://hostname.com/), which always contains a trailing slash. Returns empty string if complete_url wasn't parseable.} {
    if { [regexp {([^:\"]+://[^/]+)} $complete_url host_url] } {
	return "$host_url/"
    } else {
	return ""
    }
}

##################################################################
#
# interface to the ad-user-contributions-summary.tcl system

ns_share ad_user_contributions_summary_proc_list

if { ![info exists ad_user_contributions_summary_proc_list] || [util_search_list_of_lists $ad_user_contributions_summary_proc_list "Bookmarks" 0] == -1 } {
    lappend ad_user_contributions_summary_proc_list [list "Bookmarks" bm_user_contributions 0]
}

proc_doc bm_user_contributions {db user_id purpose} {For site admin only, returns statistics and a link to a details page} {
    if { $purpose != "site_admin" } {
	return [list]
    }
    set n_total [database_to_tcl_string $db "select count(*) as n_total 
from bm_list
where owner_id = $user_id"]
    if { $n_total == 0 }  {
	return [list]
    } else {
	return [list 0 "Bookmarks" "<ul><li><a href=\"/admin/bookmarks/index.tcl?owner_id=$user_id\">$n_total bookmarks</a></ul>\n"]
    }
}

util_report_successful_library_load
