# $Id: reject.tcl,v 3.1.2.1 2000/04/28 15:09:37 carsten Exp $
set admin_user_id [ad_verify_and_get_user_id]

if { $admin_user_id == 0 } {
    ad_returnredirect /register.tcl?return_url=[ns_urlencode "/admin/users/awaiting-approval.tcl"]
    return
}

set_the_usual_form_variables

# user_id 

set db [ns_db gethandle]
set selection [ns_db 1row $db "select first_names || ' ' || last_name as name, user_state from users where user_id = $user_id"]
set_variables_after_query


append whole_page "[ad_admin_header "Rejecting $name"]

<h2>Rejecting $name</h2>

[ad_admin_context_bar [list "index.tcl" "Users"] [list "awaiting-approval.tcl" "Approval"] "Approve One"]

<hr>

"

ns_db dml $db "update users 
set rejected_date = sysdate, user_state = 'rejected',
rejecting_user = $admin_user_id
where user_id = $user_id"


append whole_page " 
Done.

[ad_admin_footer]
"
ns_db releasehandle $db
ns_return 200 text/html $whole_page
