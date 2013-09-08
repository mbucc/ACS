# /www/intranet/employees/admin/qualification-edit.tcl

ad_page_contract {

    @author teadams@arsdigita.com
    @creation-date April 24, 2000 
    @cvs-id qualification-edit.tcl,v 3.2.6.6 2000/09/22 01:38:34 kevin Exp 
    @param qualification_id The id of the qualification we're updating
} {
    qualification_id
}



set qualification [db_string getqual "select qualification
from im_qualification_processes where qualification_id = :qualification_id"]



doc_return  200 text/html "
[ad_header "Edit Qualification"]
<h2>Edit qualification</h2>
[ad_context_bar_ws [list "/intranet/employees/admin" "Employees admin"] [list "qualification-list.tcl" "Qualification"] "Edit"]
<hr>
<form action=qualification-edit-2 method=post>
[export_entire_form]
Qualification: <input type=text name=qualification maxlength=100 [export_form_value  qualification]>
<p>
<center>
<input type=submit name=submit value=\"Edit\">
</center>
<form>
[ad_footer]
"