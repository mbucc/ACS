# /www/intranet/employees/admin/checkpoint-add.tcl

ad_page_contract {
    

    @author berkeley@arsdigita.com
    @creation-date Tue Jul 11 18:25:07 2000
    @cvs-id checkpoint-add.tcl,v 3.2.6.5 2000/09/22 01:38:32 kevin Exp
    @param return_url The usual, a url to return to
    @param stage Checkpoint stage(?)
} {
    return_url
    stage
}

doc_return  200 text/html "
[ad_header "Add $stage checkpoint"]
<h2>Add Job</h2>
[ad_context_bar_ws [list "/intranet/employees/admin" "Employees admin"] "Add $stage checkpoint"]
<hr>
<form action=checkpoint-add-2 method=post>
[export_entire_form]
Checkpoint: <input type=text name=checkpoint maxlength=100>
<center>
<input type=submit name=submit value=\"Add\">
</center>
<form>
[ad_footer]
"