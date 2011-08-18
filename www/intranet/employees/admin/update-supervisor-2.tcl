# $Id: update-supervisor-2.tcl,v 3.0.4.2 2000/04/28 15:11:07 carsten Exp $
#
# File: /www/intranet/employees/admin/update-supervisor-2.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# writes employee's supervisor to db
# 

set db [ns_db gethandle]

set_the_usual_form_variables
# user_id, supervisor_id (dp variables)

# We use data pipeline to not worry about updates vs inserts

if { ![exists_and_not_null dp.im_employee_info.user_id] } {
    ad_return_error "Browser broken" "Your browser is broken or our code is.  We didn't see a user_id for the user you're trying to update."
    return
}

dp_process -db $db -where_clause "user_id=${dp.im_employee_info.user_id}"

if { [exists_and_not_null return_url] } {
    ad_returnredirect $return_url
} else {
    ad_returnredirect index.tcl
}
