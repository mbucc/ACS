# /tcl/bookmarks-defs.tcl

ad_library {
    procedures for the bookmarks system
    
    @author aure@arsdigita.com and dh@arsdigita.com
    @date July 1999
    @cvs-id bookmarks-defs.tcl,v 3.6.2.8 2000/09/22 01:33:59 kevin Exp
}

proc bm_system_owner {} {
    return [ad_parameter SystemOwner bm [ad_system_owner]]
}

proc bm_footer {} {
    return [ad_footer [bm_system_owner]]
}

proc_doc bm_folder_selection {owner_id bookmark_id } { 

    Creates an option list of all the folders a selected object may
    move to - the resulting <select> name is 'parent_id'.

} {  

    set folder_exclusion_clauses [list "owner_id = :owner_id" "folder_p = 't'"]

    if [db_0or1row folder_exclusion  "
    select folder_p, 
           parent_id, 
           parent_sort_key, 
           local_sort_key 
    from   bm_list 
    where  bookmark_id = :bookmark_id"] {
     
	if { $folder_p == "t" } {
	    # We cannot move folders to be their own children.
	    
	    lappend folder_exclusion_clauses "
	    (parent_sort_key not like '%$parent_sort_key$local_sort_key%' or parent_sort_key is null)" 
	    lappend folder_exclusion_clauses "bookmark_id <> :bookmark_id"
	}
    } else {
	set parent_id [db_null]
    }
   
    if { $parent_id == "" } {
	set edit_form_option "<option value=\"\" selected>Top Level</option>\n"
    } else {
	set edit_form_option "<option value=\"\" > Top Level </option>\n"
    }

    set folder_count 0

    db_foreach bookmark "
    select bookmark_id, 
           local_title, 
           lpad(' ', 6*(nvl(length(parent_sort_key),0)+3), '&nbsp;') as indentation
    from   bm_list
    where [join $folder_exclusion_clauses " and "]
    order by parent_sort_key || local_sort_key" {

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

proc_doc bm_set_hidden_p {owner_id} {

    This procedure insures that the 'hidden_p' column in the 'bm_list'
    table is consistant with the privacy of the folder structure (ie a
    bookmark inside a private folder or in a folder in a private
    folder etc is considered to be hidden_p=t) 

} {
    # first, make all the bookmarks visible 
    # (unless they are explicitly marked private)
    db_dml bm_list_reset_hidden {
        update bm_list
        set    hidden_p = private_p
        where  owner_id = :owner_id
    }

    # find all private folders
    set bad_parents [db_list bm_list_get_private_folders {
	select bookmark_id
        from bm_list
        where owner_id = :owner_id
        and folder_p = 't'
        and private_p = 't'
    }]

    for {set i 0} {$i < [llength $bad_parents]} {incr i} {
	    set bad_parent_$i [lindex $bad_parents $i]
	    lappend bind_bad_parents ":bad_parent_$i"
    }
	
    if { ![empty_string_p $bad_parents] } {
	# hide the bookmarks that belong to private folders
	db_dml bm_list_hide "
	    update bm_list set hidden_p = 't'
	    where bookmark_id in (
	        select  bookmark_id
	        from    bm_list 
	        where   owner_id = :owner_id
	        connect by  prior bookmark_id = parent_id
	        start with parent_id in ([join $bind_bad_parents ","]))
	"
    }
}

proc_doc bm_set_in_closed_p {owner_id} {

    This procedure insures that the 'in_closed_p' column in the
    'bm_list' table is consistant with the open/closed of the folder
    structure (ie a bookmark inside a closed folder or in a folder in
    a closed folder etc is considered to be in_closed_p=t)  
    
} { 
    db_transaction {
    
	# Set all files to be open.
	db_dml bm_update_1 "
	update bm_list 
	set    in_closed_p = 'f' 
	where  owner_id    = :owner_id"

	# Set as in_closed_p those bookmarks which have any parent as closed.
	db_dml bm_update_2 "
	update bm_list 
	set    in_closed_p = 't' 
	where  bookmark_id in 
	   (select  bookmark_id 
	    from    bm_list
            where   owner_id = :owner_id
            connect by prior bookmark_id = parent_id
	    start with parent_id in 
	        (select bookmark_id
	         from   bm_list 
                 where  owner_id = :owner_id 
                 and    folder_p = 't' 
                 and    closed_p = 't'))"
    }
}

# you need to register this (rather than using a .tcl page)
# so that people can view exported bookmarks,
# click "Save As" and be supplied with the correct filename by default

ad_register_proc GET /bookmarks/bookmark.htm bm_export_to_netscape

proc_doc bm_export_to_netscape {} {

    Outputs a set of bookmarks in the standard Netscape bookmark.htm
    format.

} {

    set user_id [ad_verify_and_get_user_id]

    # redirect some one who hasn't logged on to the server front page
    if { $user_id == 0} {
	ad_returnredirect "/register/index?return_url=[ns_urlencode [ns_conn url]]"
	return
    }

    set name [db_string name "
    select first_names||' '||last_name as name 
    from   users 
    where  user_id = :user_id"]

    set folder_list 0

    db_foreach bm_info {
        select   bookmark_id, 
	         bm_list.url_id, 
                 local_title, 
	         creation_date, 
	         parent_id,
                 complete_url, 
	         folder_p,
                 parent_sort_key||local_sort_key as sort_key
        from     bm_list, 
                 bm_urls
        where    owner_id       = :user_id
        and      bm_list.url_id = bm_urls.url_id(+)
        order by sort_key
    } {

	set previous_parent_id [lindex $folder_list [expr [llength $folder_list]-1]]
	
	if {$parent_id != $previous_parent_id} {

	    set parent_location [lsearch -exact $folder_list $parent_id]
	    
	    if {$parent_location==-1} {
		lappend folder_list $parent_id
		append bookmark_html "<dl><p>\n\n"
	    } else { 	    
		set drop [expr [llength $folder_list]-$parent_location]
		set folder_list [lrange $folder_list 0 $parent_location]
		for {set i 1} {$i<$drop} {incr i} {
		    append bookmark_html "</dl><p>\n\n"
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

    
    doc_return  200 text/html $html
}

proc_doc bm_host_url {complete_url} {

    Takes a URL and returns the host portion of it (i.e.,
    http://hostname.com/), which always contains a trailing
    slash. Returns empty string if complete_url wasn't parseable.

} {
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

proc_doc bm_user_contributions {user_id purpose} {

    For site admin only, returns statistics and a link to a details
    page

} {
    if { $purpose != "site_admin" } {
	return [list]
    }

    set n_total [db_string count "
    select count(*) as n_total 
    from   bm_list
    where  owner_id = :user_id"]

    if { $n_total == 0 }  {
	return [list]
    } else {
	return [list 0 "Bookmarks" "<ul><li><a href=\"/admin/bookmarks/index?owner_id=$user_id\">$n_total bookmarks</a></ul>\n"]
    }
}
