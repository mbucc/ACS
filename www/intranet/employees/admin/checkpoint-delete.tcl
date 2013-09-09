# /www/intranet/employees/admin/checkpoint-delete.tcl

ad_page_contract {
    confirms delete of checkpoint
    @author berkeley@arsdigita.com
    @creation-date Tue Jul 11 19:21:11 2000
    @cvs-id checkpoint-delete.tcl,v 3.1.2.6 2000/09/22 01:38:33 kevin Exp
    @param checkpoint_id The checkpoint to delete
    @param user_id Who loses the checkpoint
    @param return_url The url to return to
} {
    checkpoint_id:integer
    user_id:integer
    {return_url "" }
}



if {[catch {db_0or1row checkpointstuff \
	"select checkpoints.checkpoint, u.first_names || ' ' || u.last_name as full_name, emp.check_note
	   from im_employee_checkpoints checkpoints, users u, im_emp_checkpoint_checkoffs emp
          where checkpoints.checkpoint_id = emp.checkpoint_id
            and u.user_id=emp.checkee
            and emp.checkee=:user_id
and emp.checkpoint_id=:checkpoint_id"} errmsg]} {
    ad_return_error "Checkpoint not found" "Checkpoint #$checkpoint_id for user $user_id was not found $errmsg"
    return

}

if { ![info exists full_name] } {
    ad_return_error "Checkpoint not found" "Checkpoint #$checkpoint_id for user $user_id was not found"
    return
}


set page_title "Confirm delete of checkpoint for $full_name"
set context_bar [ad_context_bar_ws [list ./ "Employees"] [list view?[export_url_vars user_id] "One employee"] "Delete checkpoint"]

set page_body "

Do you really want to delete the $checkpoint checkpoint for $full_name?

<p>

[im_yes_no_table checkpoint-delete-2.tcl view.tcl [list user_id checkpoint_id]]

"



doc_return  200 text/html [im_return_template]
