# /www/intranet/employees/admin/department-edit.tcl

ad_page_contract {
    @author teadams@arsdigita.com
    @creation-date April 24, 2000
    @cvs-id department-edit.tcl,v 3.2.6.6 2000/09/22 01:38:33 kevin Exp
    @param department_id The department to edit

} {
    department_id:integer

}



set department [db_string get_dept "select department
from im_departments where department_id = :department_id"]



doc_return  200 text/html "
[ad_header "Edit Department"]
<h2>Edit department</h2>
[ad_context_bar_ws [list "/intranet/employees/admin" "Employees admin"] [list "department-list.tcl" "Department"] "Edit"]
<hr>
<form action=department-edit-2 method=post>
[export_entire_form]

Department: <input type=text name=department maxlength=100 [export_form_value  department]>
<p>
<center>
<input type=submit name=submit value=\"Edit\">
</center>
<form>
[ad_footer]
"