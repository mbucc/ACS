# $Id: add-2.tcl,v 3.0.4.2 2000/04/28 15:11:09 carsten Exp $
# File: /www/intranet/procedures/add-2.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Purpose: Stores a new procedure to the db
#

set_the_usual_form_variables
# procedure_id, name, note, user_id

set creation_user [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set db [ns_db gethandle]

set exception_count 0
set exception_text ""

if [empty_string_p ${name}] {
    incr exception_count
    append exception_text "<LI>The procedure needs a name\n"
}

if [empty_string_p ${user_id}] {
    incr exception_count
    append exception_text "<LI>Missing supervisor"
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

ns_db dml $db "begin transaction"

set insert "insert into im_procedures 
(procedure_id, name, note, creation_date, creation_user) values
($procedure_id, '$QQname', '$QQnote', sysdate, $creation_user)"

if [catch {ns_db dml $db $insert} errmsg] {
    if {[database_to_tcl_string $db "select count(*) from im_procedures where procedure_id = $procedure_id"] == 0} {
        ad_return_error "Error" "Can't add procedure. Error: <PRE>$errmsg</PRE> "
        return
    } else {
        ad_returnredirect procedures.tcl
        return
    }
}

ns_db dml $db "insert into im_procedure_users 
(procedure_id, user_id, certifying_user, certifying_date) values
($procedure_id, $user_id, $creation_user, sysdate)"

ns_db dml $db "end transaction"

ad_returnredirect index.tcl