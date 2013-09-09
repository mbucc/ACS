# /www/intranet/employees/admin/checkpoint-edit.tcl

ad_page_contract {

    Edits a checkpoint (offers link to delete as well)  

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date Wed Jun 21 22:43:41 2000
    @cvs-id checkpoint-edit.tcl,v 3.1.2.5 2000/09/22 01:38:33 kevin Exp
    @param checkpoint_id The Checkpoint to delete
    @param user_id The user to lose the checkpoint
    @param return_url The url to return to
} {
    checkpoint_id:integer
    user_id:integer
    {return_url ""}
}

if { [empty_string_p $return_url] } {
    set return_url "view?[export_url_vars user_id]"
}


db_0or1row getcheckpointinfo  \
	"select checkpoints.checkpoint, u.first_names || ' ' || u.last_name as full_name, emp.check_note
	   from im_employee_checkpoints checkpoints, users u, im_emp_checkpoint_checkoffs emp
          where checkpoints.checkpoint_id = emp.checkpoint_id
            and u.user_id=emp.checkee
            and emp.checkee=:user_id
            and emp.checkpoint_id=:checkpoint_id"

if { ![info exists full_name] } {
    ad_return_error "Checkpoint not found" "Checkpoint #$checkpoint_id for user $user_id was not found"
    return
}


set page_title "Edit checkpoint for $full_name"
set context_bar [ad_context_bar_ws [list ./ "Employees"] [list view?[export_url_vars user_id] "One employee"] "Edit checkpoint"]

set checkee $user_id

set page_body "

Edit checkpoint ($checkpoint) for $full_name:

<p>

<form method=post action=checkoff-2.tcl>
[export_form_vars checkpoint_id checkee return_url]

Note: <br>
<textarea cols=30 rows=5 name=check_note>[philg_quote_double_quotes $check_note]</textarea>
<center>
<input type=submit name=submit value=\"Edit\">
</center>
<form>

<ul>
  <li> <a href=checkpoint-delete?[export_url_vars user_id checkpoint_id return_url]>Delete this checkpoint for this user</a>
</ul>

"



doc_return  200 text/html [im_return_template]

