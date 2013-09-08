# /www/intranet/employees/admin/department-list.tcl

ad_page_contract {

    @author teadams@arsdigita.com
    @creation-date April 24, 2000
    @cvs-id department-list.tcl,v 3.2.6.5 2000/09/22 01:38:33 kevin Exp
} {
}


set department_list [list]
db_foreach getdepts "select dept.department_id, dept.department from im_departments dept order by lower(dept.department)" {
    lappend department_list "$department - <a href=/admin/categories/one?category_id=$department_id>edit</a>"
} 

if { [llength $department_list] == 0 } {
    lappend department_list "<em>none</em>"
    set admin_link "/admin/categories/"
} else {
    # Select out the type for the last category we selected
    set category_type [db_string select_category_type \
	    "select category_type from categories where category_id=$department_id"]
    set admin_link "/admin/categories/one-type?[export_url_vars category_type]"
}

set context_bar [ad_context_bar_ws [list [im_url_stub]/ "Intranet"] [list "[im_url_stub]/employees/admin/" "Employees Admin"] "Departments"]

doc_return  200 text/html "
[im_header "Departments"]
<ul>
<li>[join $department_list "<li>"]

<p><li><a href=$admin_link>Manage departments</a>
</ul>
[im_footer]
"