# $Id: info-edit-2.tcl,v 3.0.4.2 2000/04/28 15:11:10 carsten Exp $
# File: /www/intranet/procedures/info-edit-2.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Purpose: Stores changes to procedure
#

set_the_usual_form_variables
# procedure_id, note

set caller_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set db [ns_db gethandle]

set exception_count 0
set exception_text ""

if [empty_string_p $name] {
    incr exception_count
    append exception_text "<LI>The procedure needs a name\n"
}

ns_db dml $db "update im_procedures set note = '$QQnote', name='$QQname' where procedure_id = $procedure_id"

ad_returnredirect info.tcl?procedure_id=$procedure_id
