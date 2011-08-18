# $Id: resolve-2.tcl,v 3.0.4.1 2000/04/28 15:08:46 carsten Exp $
#
# jkoontz@arsdigita.com July 21, 1999
#
# This page confirms that a problems in the problem log is resolved

set_form_variables
# problem_id

# we need them to be logged in
set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    
    set return_url "[ns_conn url]?[export_entire_form_as_url_vars]"

    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

set db [ns_db gethandle]

ns_db dml $db "update ec_problems_log set resolved_by=$user_id, resolved_date=sysdate where problem_id = $problem_id"

ad_returnredirect index.tcl