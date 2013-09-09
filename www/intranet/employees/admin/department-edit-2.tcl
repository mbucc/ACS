# /www/intranet/employees/admin/department-edit-2.tcl

ad_page_contract {

    @author teadams
    @creation-date April 4, 2000
    @cvs-id department-edit-2.tcl,v 3.2.2.5 2000/08/16 21:24:48 mbryzek Exp
    @param department The new department name
    @param department_id The department_id
} {
    department
    department_id:integer
}

if { [empty_string_p [string trim $department]] } {
    ad_return_complaint "Error"  "You must enter a proper name for the department"
    return
}


db_dml updatedepartment  "update im_departments
set department = :department where department_id = :department_id"

ad_returnredirect "department-list.tcl"
