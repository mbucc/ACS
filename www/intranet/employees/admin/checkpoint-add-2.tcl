# teadams on April 24, 2000
# /www/intranet/employees/admin/checkpoint-add-2.tcl

ad_page_contract {

    

    @author teadams@arsdigita.com
    @creation-date April 24, 2000
    @cvs-id checkpoint-add-2.tcl,v 3.2.2.5 2000/08/16 21:24:47 mbryzek Exp
    @param return_url The url to return to
    @param checkpoint The checkpoint 
} {
    return_url
    checkpoint
    stage
}


if {[empty_string_p $checkpoint]} {
    ad_return_complaint "Error" "You have to name your checkpoint."
    return
}



db_dml add_checkpoint "insert into im_employee_checkpoints (checkpoint_id, checkpoint,stage)  select im_employee_checkpoint_id_seq.nextval, :checkpoint, :stage from dual where
not exists (select checkpoint_id from im_employee_checkpoints where checkpoint = :checkpoint and stage = :stage)"

ad_returnredirect $return_url
