# /www/intranet/procedures/info-edit-2.tcl

ad_page_contract {
    Purpose: Stores changes to procedure

    @param procedure_id  the procedure we're editing
    @param note general notes about the procedure
    @param name the name of the procedure


    @author mbryzek@arsdigita.com
    @creation-date Jan 2000

    @cvs-id info-edit-2.tcl,v 3.2.6.10 2000/08/16 21:24:59 mbryzek Exp
} {
    procedure_id:integer
    note:html
    name:optional
}

set caller_id [ad_maybe_redirect_for_registration]


set exception_count 0
set exception_text ""

set name [string trim $name]
if [empty_string_p $name] {
    ad_return_complaint "error" "You have to give a procedure name!"
    return
}



db_dml update_procedure "update im_procedures set note = :note, name=:name 
where procedure_id = :procedure_id"

db_release_unused_handles

ad_returnredirect info?procedure_id=$procedure_id
