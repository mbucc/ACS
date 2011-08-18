#
# /portals/admin/manage-portal-2.tcl
#
# Updates the portal table page map given all of the users changes on manage-portal.tcl's GUI
#
# by aure@arsdigita.com and dh@arsdigita.com
#
# Last modified: 10/8/1999
#
# $Id: manage-portal-2.tcl,v 3.0.4.2 2000/04/28 15:11:18 carsten Exp $
#

#ad_page_variables {left right group_id}
set_the_usual_form_variables
# left, right, group_id

set db [ns_db gethandle]

# -------------------------------------------
# verify user
set user_id [ad_verify_and_get_user_id]
portal_check_administrator_maybe_redirect $db  $user_id $group_id
# -------------------------------------------

# good list is the list of tables on this group's portal pages after update
set good_list ""
# page_list is the resulting page_id's of pages having tables after update
set page_list ""

ns_db dml $db "begin transaction"

# loop over each side of each page left then right and update portal table page map accordingly

set i 0
foreach left_list $left {
    # We know that left and right each have one list per page.
    set right_list [lindex $right $i]
    
    incr i

    # Get page_id for page $i
    set page_id [database_to_tcl_string_or_null $db "
        select page_id 
        from  portal_pages
        where group_id = $group_id
        and   page_number = $i"]

    if {[empty_string_p $page_id] } {
	# the page is not already in the database
	
	if { [ llength $right_list] > 0  || [ llength $left_list ] > 0 } {
	    # Stuff is being moved onto this new page - create an entry for it in the database
 
	    set page_id [database_to_tcl_string $db  "select portal_page_id_sequence.nextval from dual"]

	    ns_db dml $db "
   	        insert into portal_pages
	        (page_id, group_id, page_number, page_name)
	        values
	        ($page_id, $group_id, $i, '[DoubleApos [lindex $hiddennames [expr $i-1]]]')"

	}
    } 

    if {![empty_string_p $page_id]} {
	# The page exists in the database

	# Update the name of the pre-existing page
	ns_db dml $db "
	    update portal_pages
	    set    page_name = '[DoubleApos [lindex $hiddennames [expr $i-1]]]'
	    where  group_id = $group_id
	    and    page_id = $page_id"

	lappend page_list $page_id

	# do the left side
	set sort_key 0
	foreach table_id $left_list {
	     
	    lappend good_list $table_id
	
	    incr sort_key
	    
	    # Get original_page_id for this table 
	    set original_page_id [database_to_tcl_string_or_null $db "
	        select p.page_id 
	        from   portal_pages p, portal_table_page_map m
	        where  group_id = $group_id
	        and    table_id  = $table_id
	        and    m.page_id = p.page_id"]
	    
	    if {[empty_string_p $original_page_id]} {
		ns_db dml $db "
		    insert into portal_table_page_map
		    (table_id, page_id, sort_key, page_side)
		    values
		    ($table_id, $page_id, $sort_key, 'l')"
	    } else {
		# Move this table
		ns_db dml $db "
		    update portal_table_page_map
		    set    page_id = $page_id,
		           sort_key = $sort_key,
		           page_side = 'l'
	   	    where  table_id = $table_id
		    and    page_id = $original_page_id"
	    }
	}
	
	# do the right side
	set sort_key 0
	foreach table_id $right_list {

	    lappend good_list $table_id
 	    
	    incr sort_key

	     # Get original_page_id for this table
	    
	    set original_page_id [database_to_tcl_string_or_null $db "
	        select p.page_id 
	        from portal_pages p, portal_table_page_map m
	        where group_id = $group_id
	        and   table_id  = $table_id
	        and   m.page_id = p.page_id"]

	    if {[empty_string_p $original_page_id]} {
		ns_db dml $db "
		    insert into portal_table_page_map
		    (table_id, page_id, sort_key, page_side)
		    values
		    ($table_id, $page_id, $sort_key, 'r')"
	    } else {
		ns_db dml $db "
		    update portal_table_page_map
		    set    page_id = $page_id,
		           sort_key = $sort_key,
		           page_side = 'r'
		    where  table_id = $table_id
		    and    page_id = $original_page_id"
	    }
	}
    }
}    

if {![empty_string_p $good_list] && ![empty_string_p $page_list]} {
    # delete tables that didn't appear in our list (hence they were javascript-deleted)
    ns_db dml $db "
        delete from portal_table_page_map
        where table_id not in ([join $good_list ,])
        and page_id in ([join $page_list ,])"
}

if {[empty_string_p $good_list] && ![empty_string_p $page_list] } {
    # delete all tables
    ns_db dml $db "delete from portal_table_page_map where page_id in ([join $page_list ,])"
}

ns_db dml $db "end transaction"



# remove orphaned pages with no tables on them
ns_db dml $db "delete from portal_pages where page_id not in (select page_id from portal_table_page_map)"

# ----------------------------------------------------------------------------------
# get all the page_ids for pages with stuff and flush memoization for them

set page_id_list [database_to_tcl_list $db "
    select pp.page_id 
    from   portal_pages pp
    where  pp.group_id = $group_id
    and    pp.page_id in (select pm.page_id from portal_table_page_map pm)   
    order by page_number"]

set new_page_number 0
foreach page_id $page_id_list {
    incr new_page_number
    ns_db dml $db "
        update portal_pages
        set page_number = $new_page_number
        where page_id = $page_id "
}

set page_list [database_to_tcl_list $db  "
    select page_number 
    from portal_pages 
    where group_id = $group_id"] 

ns_db releasehandle $db

foreach page_number $page_list {
    util_memoize_flush "portal_display_page $group_id $page_number group"
}

ad_returnredirect manage-portal?group_id=$group_id








