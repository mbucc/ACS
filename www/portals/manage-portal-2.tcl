# www/portals/manage-portal-2.tcl

ad_page_contract {
    Updates the portal table page map given all of the users 
    changes on manage-portal.tcl's GUI (user level version)

    @author aure@arsdigita.com 
    @author dh@arsdigita.com
    @param left
    @param right
    @param hiddennames
    @creation-date 10/8/1999
    @cvs-id manage-portal-2.tcl,v 3.3.2.10 2000/07/28 18:51:31 psu Exp
} {
    left
    right
    hiddennames
}


set user_id [ad_verify_and_get_user_id]

# good list is the list of tables on this group's portal pages after update
set good_list ""
# page_list is the resulting page_id's of pages having tables after update
set page_list ""

# temp var to use for bind vars

db_transaction {

    # loop over each side of each page left then right and update portal table page map accordingly

    set page_count 0

    # left_list is a list of lists. one list of table numbers per portal page.
    foreach left_list $left {

        # this will keep track of the portal tables that we saw on this page.
        # anything not in this list at the end of the loop is removed from the
        # portal_table_page_map later.
        set good_list [list]

        # We know that left and right each have one list per page.
        set right_list [lindex $right $page_count]
        
        incr page_count
        set bind_var_hiddennames [lindex $hiddennames [expr ${page_count}-1]]

        # Get page_id for page $i -Dave
        set page_id [db_string portal_manage_portal_2_get_page_id "
        select page_id 
        from  portal_pages
        where user_id = :user_id
        and   page_number = :page_count"  -default ""]

        if {[empty_string_p $page_id] } {
            # the page is not already in the database	
            
            if { [ llength $right_list] > 0  || [ llength $left_list ] > 0 } {
                # Stuff is being moved onto this new page - create an entry for it in the database
                
                set page_id [db_string portal_manage_portal_2_get_next_page_id "select portal_page_id_sequence.nextval from dual"]

                db_dml portal_manage_portal_2_insert_new_portal_page "
                insert into portal_pages
                (page_id, user_id, page_number, page_name)
                values
                (:page_id, :user_id, :page_count, :bind_var_hiddennames )" 

            }
        }

        # The page exists in the database

        # Update the name of the pre-existing page
        db_dml portal_manage_portal_2_update_portal_page "
        update portal_pages
        set    page_name = :bind_var_hiddennames
        where  user_id = :user_id
        and    page_id = :page_id" 

        lappend page_list $page_id

        # do the left side
        set sort_key 0
        foreach table_id $left_list {
            
            lappend good_list $table_id
            
            incr sort_key

            # Get original_page_id for this table 

            set original_page_id [db_string portal_manage_portal_2_get_original_page_id "
            select p.page_id 
            from   portal_pages p, portal_table_page_map m
            where  user_id = :user_id
            and    table_id  = :table_id
            and    page_number  = :page_count
            and    m.page_id = p.page_id"  -default ""]
            

            if {[empty_string_p $original_page_id]} {
                db_dml portal_manage_portal_2_insert_new_portal_page_map "
                insert into portal_table_page_map
                (table_id, page_id, sort_key, page_side)
                values
                (:table_id, :page_id, :sort_key, 'l')"

            } else {
                # Move this table

                db_dml portal_manage_portal_2_update_portal_page_map "
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
            
            set original_page_id [db_string portal_manage_2_get_original_page_id_right "
            select p.page_id 
            from portal_pages p, portal_table_page_map m
            where user_id = :user_id
            and   table_id  = :table_id
            and    page_number  = :page_count
            and   m.page_id = p.page_id"  -default ""]

            if {[empty_string_p $original_page_id]} {
                db_dml portal_manage_2_insert_new_portal_page_map_right "
                insert into portal_table_page_map
                (table_id, page_id, sort_key, page_side)
                values
                (:table_id, :page_id, :sort_key, 'r')"
            } else {
                db_dml portal_manage_2_update_portal_page_map_right "
                update portal_table_page_map
                set    page_id = :page_id,
                sort_key = :sort_key,
                page_side = 'r'
                where  table_id = :table_id
                and    page_id = :original_page_id" 
            }
        }

        # update the database rep of this portal page.
        # moved it in here because we have to do this page by page, otherwise
        # bugs happen.

        set bind_vars_good_list [join $good_list ,]

        set vars_good_list {}

        if {![empty_string_p $good_list] && ![empty_string_p $page_list]} {
            # delete tables that didn't appear in our list (hence they were javascript-deleted)
            
            # Note: Oracle does not do bind variables with a list of integer. It will treat the whole list as a single integer. 
            # Therefore, it will return an Oracle error.
            # Work around this is the following:

            for {set i 0} {$i < [llength $good_list]} {incr i} {
                set vars_good_list_$i [lindex $good_list $i]
                lappend vars_good_list ":vars_good_list_$i"
            }

            db_dml portal_manage_2_delete_portal_page_map "
            delete from portal_table_page_map
            where table_id not in ([join $vars_good_list ","])
            and page_id = :page_id"
        }

        if {[empty_string_p $good_list] && ![empty_string_p $page_list] } {
            # delete all tables

            db_dml portal_manage_2_delete_all_table "
            delete from portal_table_page_map
            where page_id = :page_id"
        }
    }
} on_error {
    ad_return_complaint "DML Error" $errmsg
    return 0
}

# remove orphaned pages with no tables on them
db_dml portal_manage_portal_2_delete_orphane_page "delete from portal_pages where page_id not in (select page_id from portal_table_page_map)"

# get all the page_ids for pages with stuff
set page_id_list [db_list portal_manage_portal_2_get_page_ids "
    select pp.page_id 
    from   portal_pages pp
    where  pp.user_id = :user_id
    and    pp.page_id in (select pm.page_id from portal_table_page_map pm)   
    order by page_number"]

set new_page_number 0
foreach page_id $page_id_list {

    incr new_page_number
    db_dml portal_manage_portal_2_update_page_number "
    update portal_pages
    set page_number = :new_page_number
    where page_id = :page_id"

}

db_release_unused_handles

ad_returnredirect manage-portal
