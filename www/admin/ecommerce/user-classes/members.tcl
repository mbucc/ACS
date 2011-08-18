# $Id: members.tcl,v 3.0 2000/02/06 03:22:06 ron Exp $
set_the_usual_form_variables

# user_class_id

ReturnHeaders

set db [ns_db gethandle]

set user_class_name [database_to_tcl_string $db "select user_class_name from ec_user_classes where user_class_id = $user_class_id"]

ns_write "[ad_admin_header "Members of $user_class_name"]

<h2>Members of $user_class_name</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "User Classes"] [list "one.tcl?[export_url_vars user_class_id user_class_name]" "One Class"] "Members" ] 

<hr>

<ul>
"

set selection [ns_db select $db "select 
users.user_id, first_names, last_name, email,
m.user_class_approved_p
from users, ec_user_class_user_map m
where users.user_id = m.user_id
and m.user_class_id=$user_class_id"]

set user_counter 0
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    ns_write "<li><a href=\"/admin/users/one.tcl?user_id=$user_id\">$first_names $last_name</a> ($email) "

    if { [ad_parameter UserClassApproveP ecommerce] } {
	ns_write "<font size=-1>[ec_decode $user_class_approved_p "t" "" "un"]approved</font> "
    }

    ns_write "(<a href=\"member-delete.tcl?[export_url_vars user_class_name user_class_id user_id]\">remove</a>"

    if { [ad_parameter UserClassApproveP ecommerce] } {
	if { $user_class_approved_p == "t" } {
	    ns_write " | <a href=\"approve-toggle.tcl?[export_url_vars user_class_id user_id user_class_approved_p]\">unapprove</a>"
	} else {
	    ns_write " | <a href=\"approve-toggle.tcl?[export_url_vars user_class_id user_id user_class_approved_p]\">approve</a>"
	}
    }

    ns_write ")\n"
    incr user_counter
}

if { $user_counter == 0 } {
    ns_write "There are no users in this user class."
}

ns_write "</ul>

[ad_admin_footer]
"
