# $Id: view-verbose.tcl,v 3.1.2.1 2000/04/28 15:09:38 carsten Exp $
#
# view-verbose.tcl
# 
# by teadams@mit.edu and philg@mit.edu in ancient times (1998?)
# 
# displays an HTML page with a list of the users in a class
# 

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

who $description among <a href=\"index.tcl\">all users of [ad_system_name]</a>

<hr>

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

set new_set [ns_set copy [ns_conn form]]
ns_set put $new_set include_contact_p 1
ns_set put $new_set include_demographics_p 1

set query [ad_user_class_query $new_set]
append ordered_query $query "\n" $order_by_clause

set selection [ns_db select $db $ordered_query]
set count 0
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    incr count
    append whole_page "<li><a href=\"one.tcl?user_id=$user_id\">$first_names $last_name</a> ($email)"
    if ![empty_string_p $demographics_summary] {
	append whole_page ", $demographics_summary"
    }
    if ![empty_string_p $contact_summary] {
	append whole_page ", $contact_summary"
    }
    append whole_page "\n"
}

if { $count == 0 } {
    append whole_page "no users found meeting these criteria"
}

append whole_page "</ul>

[ad_admin_footer]
"
ns_db releasehandle $db
ns_return 200 text/html $whole_page
