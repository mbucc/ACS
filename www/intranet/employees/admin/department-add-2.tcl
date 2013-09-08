# teadams on April 24, 2000
# /www/intranet/employees/admin/department-add-2.tcl

ad_page_contract {

    @author berkeley@arsdigita.com
    @creation-date Tue Jul 11 20:03:29 2000
    @cvs-id department-add-2.tcl,v 3.2.2.4 2000/07/21 04:01:11 ron Exp
    @param return_url An optional arguement for jumping back 
    @param department The department to create
} {
    {return_url  "department-list.tcl"}
    department
}


if { [empty_string_p [string trim $department]] } {
    ad_return_complaint "Error"  "You must enter a proper name for the department"
    return
}


#create view im_departments as
#select category_id as department_id, category as department
#from categories
#where category_type = 'Intranet Department';

# Therefore this insert never works.

db_dml add_dept "insert into im_departments (department_id,department)  select im_departments_seq.nextval, :department from dual where
not exists (select department_id from im_departments where department = :department)"

ad_returnredirect $return_url

