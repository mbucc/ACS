# /www/intranet/procedures/user-edit-2.tcl

ad_page_contract {
    Purpose: Edits/inserts note about a procedure

    @param procedure_id refers to procedure we are modifying
    @param user_id user being added to certification list
    @param note notes/restrictions about the procedure

    @author mbryzek@arsdigita.com
    @creation-date Jan 2000

    @cvs-id user-edit-2.tcl,v 3.2.6.7 2000/08/16 21:25:00 mbryzek Exp
} {
    procedure_id:integer,notnull
    user_id:optional
    note
}

set certifying_user [ad_maybe_redirect_for_registration]

#Complain if there is no user_id passed

if {[empty_string_p $user_id]} {
    ad_return_complaint "Error" "You have to select a user to certify."
}

if {[db_string certify_user "select count(*) from im_procedure_users where user_id = :certifying_user and procedure_id = :procedure_id"] == 0} {
    ad_return_error "Error" "You're not allowed to certify new users"
    return
}


db_dml update_procedure "update im_procedure_users set note = :note
where procedure_id = :procedure_id
and user_id = :user_id"

# if the procedure doesn't already exist, create it

if {[db_resultrows] == 0} {
    db_dml create_procedure "insert into im_procedure_users
(procedure_id, user_id, note, certifying_user, certifying_date) values
(:procedure_id, :user_id, :note, :certifying_user, sysdate)"
}

db_release_unused_handles

ad_returnredirect info?[export_url_vars procedure_id]
