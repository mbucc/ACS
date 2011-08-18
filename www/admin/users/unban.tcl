# $Id: unban.tcl,v 3.0 2000/02/06 03:31:37 ron Exp $
set_form_variables

# user_id

set db [ns_db gethandle]

ns_db dml $db "update users set user_state = 'authorized' where user_id = $user_id"

ns_return 200 text/html "[ad_admin_header "Account resurrected"]

<h2>Account Resurrected</h2>

<hr>

[database_to_tcl_string $db "select first_names || ' ' || last_name from users where user_id = $user_id"] has been marked \"not deleted\".

[ad_admin_footer]
"
