# www/portals/admin/manage-portal-2.tcl

ad_page_contract {
    Updates the portal table page map given all of the users changes on manage-portal.tcl's GUI

    @author aure@arsdigita.com 
    @author dh@arsdigita.com
    @param left
    @param right
    @param group_id
    @param hiddennames
    @creation-date 10/8/1999
    @cvs-id manage-portal-2.tcl,v 3.3.2.8 2000/07/28 18:51:31 psu Exp

} {
    left
    right
    {group_id:naturalnum}
    hiddennames
}

# -------------------------------------------
# verify user
set user_id [ad_verify_and_get_user_id]
portal_check_administrator_maybe_redirect  $user_id $group_id
# -------------------------------------------

# good list is the list of tables on this group's portal pages after update
set good_list ""
# page_list is the resulting page_id's of pages having tables after update
set page_list ""

db_transaction {

# loop over each side of each page left then right and update portal table page map accordingly

    set i 0
    foreach left_list $left {
        # We know that left and right each have one list per page.
        set right_list [lindex $right $i]
        
        incr i

        # this will keep track of the portal tables that we saw on this page.
        # anything not in this list at the end of the loop is removed from the
        # portal_table_page_map later.
        set good_list [list]

        # Get page_id for page $i
        set page_id [db_string portals_admin_manage_portal_2_get_page_id "
        select page_id 
        from  portal_pages
        where group_id = :group_id
        and   page_number = :i" -default "" ]

        if {[empty_string_p $page_id] } {
            # the page is not already in the database
            
            if { [ llength $right_list] > 0  || [ llength $left_list ] > 0 } {
                # Stuff is being moved onto this new page - create an entry for it in the database
                
                set page_id [db_string portals_admin_manage_portal_2_get_next_page_id  "select portal_page_id_sequence.nextval from dual"]
                
                set page_name [lindex $hiddennames [expr $i-1]]
                db_dml portals_admin_manage_portal_2_insert_new_page "
   	        insert into portal_pages
	        (page_id, group_id, page_number, page_name)
	        values
	        (:page_id, :group_id, :i, :page_name)"

            }
        } 

        if {![empty_string_p $page_id]} {
            # The page exists in the database

            # Update the name of the pre-existing page
            set page_name [lindex $hiddennames [expr $i-1]]
            db_dml portals_admin_manage_portal_update_page_name "
	    update portal_pages
	    set    page_name = :page_name
	    where  group_id = :group_id
	    and    page_id = :page_id"

            lappend page_list $page_id

            # do the left side
            set sort_key 0
            foreach table_id $left_list {
                
                lappend good_list $table_id
                
                incr sort_key
                
                # Get original_page_id for this table 
                set original_page_id [db_string portals_admin_manage_portal_get_original_page_id "
	        select p.page_id 
	        from   portal_pages p, portal_table_page_map m
	        where  group_id = :group_id
                and    page_number = :i
	        and    table_id  = :table_id
	        and    m.page_id = p.page_id" -default ""]
                
                if {[empty_string_p $original_page_id]} {
                    db_dml portals_admin_manage_portal_insert_new_page "
		    insert into portal_table_page_map
		    (table_id, page_id, sort_key, page_side)
		    values
		    (:table_id, :page_id, :sort_key, 'l')"
                } else {
                    # Move this table
                    db_dml portals_admin_manage_portal_update_table_location "
		    update portal_table_page_map
		    set    page_id = :page_id,
                    sort_key = :sort_key,
                    page_side = 'l'
	   	    where  table_id = :table_id
		    and    page_id = :original_page_id"
                }
            }
            
            # do the right side
            set sort_key 0
            foreach table_id $right_list {

                lappend good_list $table_id
                
                incr sort_key

                # Get original_page_id for this table
                
                set original_page_id [db_string portals_admin_get_original_page_id_2 "
	        select p.page_id 
	        from portal_pages p, portal_table_page_map m
	        where group_id = :group_id
                and   page_number = :i
	        and   table_id  = :table_id
	        and   m.page_id = p.page_id"  -default ""]

                if {[empty_string_p $original_page_id]} {
                    db_dml portals_admin_manage_portal_insert_new_page_right_side "
		    insert into portal_table_page_map
		    (table_id, page_id, sort_key, page_side)
		    values
		    (:table_id, :page_id, :sort_key, 'r')"
                } else {
                    db_dml portals_admin_manage_portal_update_page_right_side "
		    update portal_table_page_map
		    set    page_id = :page_id,
                    sort_key = :sort_key,
                    page_side = 'r'
		    where  table_id = :table_id
		    and    page_id = :original_page_id"
                }
            }
        }

        # update the database rep of this portal page.
        # moved it in here because we have to do this page by page, otherwise
        # bugs happen.

        if {![empty_string_p $good_list] && ![empty_string_p $page_list]} {
            # delete tables that didn't appear in our list (hence they were javascript-deleted)
            db_dml portals_admin_manage_portal_delete_tables "
            delete from portal_table_page_map
            where table_id not in ([join $good_list ,])
            and page_id = :page_id"
        }

        if {[empty_string_p $good_list] && ![empty_string_p $page_list] } {
            # delete all tables
            db_dml portals_admin_manage_portal_delete_all_tables "delete from portal_table_page_map where page_id = :page_id"
        }


    }    
} on_error {
    ad_return_complaint "DML Error" $errmsg
    return 0
}

# remove orphaned pages with no tables on them
db_dml portals_admin_manage_portal_remove_orphane "delete from portal_pages where page_id not in (select page_id from portal_table_page_map)"

# ----------------------------------------------------------------------------------
# get all the page_ids for pages with stuff and flush memoization for them

set page_id_list [db_list portals_admin_manage_portal_get_page_id_list "
    select pp.page_id 
    from   portal_pages pp
    where  pp.group_id = :group_id
    and    pp.page_id in (select pm.page_id from portal_table_page_map pm)   
    order by page_number"]

set new_page_number 0
foreach page_id $page_id_list {
    incr new_page_number
    db_dml portals_admin_manage_portal_update_new_page_number "
        update portal_pages
        set page_number = :new_page_number
        where page_id = :page_id "
}

set page_list [db_list portals_admin_manage_portal_list_pages  "
    select page_number 
    from portal_pages 
    where group_id = :group_id"] 

foreach page_number $page_list {
    util_memoize_flush "portal_display_page $group_id $page_number group"
}

db_release_unused_handles
ad_returnredirect manage-portal?group_id=$group_id

