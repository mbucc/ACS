# /www/intranet/employees/admin/checkoff.tcl

ad_page_contract {
    @author teadams@arsdigita.com
    @creation-date  April 24, 2000
    @cvs-id checkoff.tcl,v 3.2.6.8 2000/09/22 01:38:32 kevin Exp
    @param return_url The url we return to
    @param checkpoint_id The id for this checkpoint
    @param checkee The user_id of the person checked off
} {
    return_url:
    checkpoint_id
    checkee
}




set checkpoint [db_string getcheckpoint "select checkpoint
from im_employee_checkpoints where checkpoint_id = :checkpoint_id"]

set checkee_name [db_string getcheckeename "select first_names || ' ' || last_name from users where user_id=:checkee"]



doc_return  200 text/html "
[ad_header "Checkoff $checkee_name on $checkpoint"]
<h2>Checkoff $checkee_name on $checkpoint</h2>
[ad_context_bar_ws [list "/intranet/employees/admin" "Employees admin"] "Checkoff"]
<hr>
<form action=checkoff-2 method=post>
[export_entire_form]
Note: <br>
<textarea cols=30 rows=5 name=check_note></textarea>
<center>
<input type=submit name=submit value=\"Add\">
</center>
<form>
[ad_footer]
"