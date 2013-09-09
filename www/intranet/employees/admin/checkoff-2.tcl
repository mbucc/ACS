# /www/intranet/employees/admin/checkoff-2.tcl

ad_page_contract {
    @author teadams@arsdigita.com
    @creation-date April 24, 2000
    @cvs-id checkoff-2.tcl,v 3.2.2.6 2000/08/16 21:24:47 mbryzek Exp
    @param return_url The url we return to
    @param checknote The note for this checkpoint
    @param checkpoint_id The id for this checkpoint
    @param checkee The user_id of the person checked off
} {
    return_url
    check_note
    checkpoint_id:integer
    checkee:integer
}


set user_id [ad_verify_and_get_user_id]

    db_dml insert_checkpoint_stat "insert into im_emp_checkpoint_checkoffs (checkpoint_id, checkee, checker, check_date, check_note) select :checkpoint_id, :checkee, [ad_verify_and_get_user_id], sysdate, :check_note from dual
where not exists (select checkpoint_id from im_emp_checkpoint_checkoffs where checkpoint_id = :checkpoint_id  and checkee = :checkee)"

if {[db_resultrows] == 0} {
    db_dml update_checkpoint_stat "update im_emp_checkpoint_checkoffs set
checker = [ad_verify_and_get_user_id],
check_date = sysdate,
check_note = :check_note
where checkpoint_id = :checkpoint_id
and checkee = :checkee"
}

ad_returnredirect $return_url
