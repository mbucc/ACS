# /www/press/admin/delete-2.tcl

ad_page_contract {
    
    Delete an existing press item

    @author  Ron Henderson (ron@arsdigita.com)
    @created December 1999
    @cvs-id  delete-2.tcl,v 3.3.6.5 2000/09/16 19:05:49 ron Exp
} {
    press_items:notnull
}

set dbl_clk_ck [db_string press_del_dclk "
select count(*) from press where press_id in ([join $press_items ","])"]

if {$dbl_clk_ck == 0} {
    ad_return_warning "Press Items Do Not Exist" "The press items
    you select do not exist.  Perhaps you already deleted them?"
    return 
}

# Delete the press items and redirect to the admin page

db_dml press_items_delete "delete from press where press_id in ([join $press_items ","])"
db_release_unused_handles

ad_returnredirect ""
