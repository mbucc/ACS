# File:  events/admin/reg-wait-list-2.tcl
# Owner: bryanche@arsdigita.com
# Purpose: 
#####

ad_page_contract {
    Update registration status for one registration to 'waiting'

    @param reg_id the registration to update
    @new_comment a comment explaining why we are wait-listing

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id reg-wait-list-2.tcl,v 3.3.2.4 2000/07/21 03:59:41 ron Exp
} {
    {reg_id:integer,notnull}
    {new_comment:html,trim,optional [db_null]}
}

set user_id [ad_maybe_redirect_for_registration]



set reg_check [db_0or1row sel_reg "
select r.comments, to_char(sysdate, 'YYYY-MM-DD HH24:MI') as timestamp,
u.email as admin_email
from events_registrations r, users u
where r.reg_id = :reg_id
and u.user_id = :user_id
"]

if {!$reg_check} {
    ad_return_warning "Could Not Find Registration" "Registration 
    $reg_id was not found in the database."

    return
}

if {![empty_string_p $new_comment]} {
    
    append comments "
    -------------
    $admin_email updated registration status from \"pending\" to \"waiting\"
    on $timestamp:
    $new_comment
    -------------
    "
    set comment_sql ", comments = :comments"
} else {
    set comment_sql ""
}

#set the reg_state to be waiting
db_dml unused "update events_registrations
set reg_state = 'waiting' $comment_sql
where reg_id = :reg_id"

set reg_email [db_string unused "
 select u.email
   from users u, events_registrations r
  where r.reg_id = :reg_id
    and u.user_id = r.user_id"]

db_release_unused_handles

ad_returnredirect "reg-view.tcl?[export_url_vars reg_id]"