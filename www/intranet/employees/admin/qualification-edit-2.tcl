# 
# /www/intranet/employees/admin/qualification-edit-2.tcl

ad_page_contract {

    @author teadams@arsdigita.com
    @creation-date teadams on April 24, 2000
    @cvs-id qualification-edit-2.tcl,v 3.2.2.4 2000/08/16 21:24:50 mbryzek Exp
    @param qualification_id The id of the qualification we're editing
    @param qualification The new qualification 
} {
    qualification
    qualification_id:integer
}




db_dml updatequal "update im_qualification_processes
set qualification = :qualification where qualification_id = :qualification_id"

ad_returnredirect "qualification-list.tcl"
