# File:  events/admin/reg-comments-2.tcl
# Owner: bryanche@arsdigita.com
# Purpose:  Update comments for one registration
#####

ad_page_contract {
    Updates comments for a registration.

    @param reg_id the registration whose comments we're updating
    @param comments the comment we're updating

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id reg-comments-2.tcl,v 3.4.6.4 2000/07/21 03:59:40 ron Exp
} {
    {reg_id:integer,notnull}
    {comments:html,trim [db_null]}
}

db_dml update_reg "update events_registrations set comments=:comments
                where reg_id = :reg_id"

db_release_unused_handles

ad_returnredirect "reg-view.tcl?reg_id=$reg_id"

##### 
