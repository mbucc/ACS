# $Id: unsubscribe-2.tcl,v 3.0 2000/02/06 03:53:41 ron Exp $
set user_id [ad_get_user_id]

set db [ns_db gethandle]

ns_db dml $db "update users set user_state='deleted' where user_id = $user_id"

ns_return 200 text/html "[ad_header "Account deleted"]

<h2>Account Deleted</h2>

<hr>

Your account at [ad_system_name] has been marked \"deleted\".

[ad_footer]
"
