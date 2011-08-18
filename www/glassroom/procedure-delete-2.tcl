# $Id: procedure-delete-2.tcl,v 3.0.4.1 2000/04/28 15:10:46 carsten Exp $
# procedure-delete-2.tcl -- remove a procedure from glassroom_procedures
#

set_the_usual_form_variables

# Expects procedure_name


if { [ad_read_only_p] } {
    ad_return_read_only_maintenance_message
    return
}


# check for user

set user_id [ad_verify_and_get_user_id]

if { $user_id == 0 } {
    ad_returnredirect "/register.tcl?return_url=[ns_urlencode [ns_conn url]]"
    return
}




# emit the page contents

ReturnHeaders

ns_write "[ad_header "Procedure \"$procedure_name\" Deleted"]

<h2>Procedure \"$procedure_name\" Deleted</h2>
<hr>
"

set delete_sql "delete from glassroom_procedures where procedure_name='$QQprocedure_name'"

#!!! what to do if delete fails...

set db [ns_db gethandle]

ns_db dml $db $delete_sql

ns_db releasehandle $db


ns_write "
Deletion of $procedure_name confirmed.

<p>


<a href=index.tcl>Return to the Glass Room</a>

[glassroom_footer]
"
