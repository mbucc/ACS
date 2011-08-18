# $Id: view.tcl,v 3.1.2.1 2000/04/28 15:09:38 carsten Exp $
set admin_user_id [ad_verify_and_get_user_id]

if { $admin_user_id == 0 } {
    ad_returnredirect /register.tcl?return_url=[ns_urlencode "/admin/users/"]
    return
}

# we get a form that specifies a class of user, plus maybe an order_by
# spec

set description [ad_user_class_description [ns_conn form]]


append whole_page "[ad_admin_header "Users who $description"]

<h2>Users</h2>

[ad_admin_context_bar [list "index.tcl" "Users"] "View Class"]


<hr>

Class description:  users who $description.

<P>


"

if { [ns_queryget order_by] == "email" } {
    set order_by_clause "order by upper(email),upper(last_name),upper(first_names)"
    set option "<a href=\"view.tcl?order_by=name&[export_entire_form_as_url_vars]\">sort by name</a>"
} else {
    set order_by_clause "order by upper(last_name),upper(first_names), upper(email)"
    set option "<a href=\"view.tcl?order_by=email&[export_entire_form_as_url_vars]\">sort by email address</a>"
}


set db [ns_db gethandle]

# we print out all the users all of the time 
append whole_page "

$option

<ul>"

set query [ad_user_class_query [ns_conn form]]
append ordered_query $query "\n" $order_by_clause

set selection [ns_db select $db $ordered_query]
set count 0
while { [ns_db getrow $db $selection] } {
    set_variables_after_query

    incr count
    append whole_page "<li><a href=\"one.tcl?user_id=$user_id\">$first_names $last_name</a> ($email) \n"

    if {$user_state == "need_email_verification_and_admin_approv" || $user_state ==	"need_admin_approv"}  {
	append whole_page "<font color=red>$user_state</font> <a target=approve href=approve.tcl?[export_url_vars user_id]>Approve</a> | <a  target=approve href=reject.tcl?[export_url_vars user_id]>Reject</a>"
    }
    
}

if { $count == 0 } {
    append whole_page "no users found meeting these criteria"
}

append whole_page "</ul>

[ad_admin_footer]
"
ns_db releasehandle $db
ns_return 200 text/html $whole_page
