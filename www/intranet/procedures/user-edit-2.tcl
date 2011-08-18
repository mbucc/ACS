# $Id: user-edit-2.tcl,v 3.0.4.2 2000/04/28 15:11:10 carsten Exp $
# File: /www/intranet/procedures/user-edit-2.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Purpose: Edits/inserts note about a procedure
#

set_the_usual_form_variables
# procedure_id, user_id, note

set certifying_user [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set db [ns_db gethandle]

if {[database_to_tcl_string $db "select count(*) from im_procedure_users where user_id = $certifying_user and procedure_id = $procedure_id"] == 0} {
    ad_return_error "Error" "You're not allowed to certify new users"
    return
}

set exception_count 0
set exception_text ""

if [empty_string_p $user_id] {
    incr exception_count
    append exception_text "<LI>Missing name of user to certify\n"
}

ns_db dml $db "update im_procedure_users set note = '$QQnote'
where procedure_id = $procedure_id
and user_id = $user_id"

if {[ns_ora resultrows $db] == 0} {
    ns_db dml $db "insert into im_procedure_users
(procedure_id, user_id, note, certifying_user, certifying_date) values
($procedure_id, $user_id, '$QQnote', $certifying_user, sysdate)"
}

ad_returnredirect info.tcl?[export_url_vars procedure_id]
