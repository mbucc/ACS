# /www/intranet/employees/admin/checkpoint-delete-2.tcl

ad_page_contract {
    deletes checkpoint for a user
    @author (Michael Bryzek) mbryzek@arsdigita.com 
    @creation-date Wed Jun 21 23:18:31 2000
    @cvs-id checkpoint-delete-2.tcl,v 3.1.2.5 2000/08/16 21:24:47 mbryzek Exp
    @param checkpoint_id The Checkpoint to delete
    @param user_id The user to lose the checkpoint
    @param return_url The url to return to
} {
    checkpoint_id:integer
    user_id:integer
    {return_url ""}
}



db_dml delcheckpoint "delete from im_emp_checkpoint_checkoffs emp
where emp.checkee=:user_id
and emp.checkpoint_id=:checkpoint_id"

if { ![empty_string_p $return_url] } {
    ad_returnredirect $return_url    
} else {
    ad_returnredirect view?[export_url_vars user_id]
}

