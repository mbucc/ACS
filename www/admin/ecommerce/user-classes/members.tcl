#  www/admin/ecommerce/user-classes/members.tcl
ad_page_contract {
    @param user_class_id
  @author
  @creation-date
  @cvs-id members.tcl,v 3.1.6.5 2000/09/22 01:35:06 kevin Exp
} {
    user_class_id:notnull
}




set user_class_name [db_string get_uc_name "select user_class_name from ec_user_classes where user_class_id = :user_class_id"]

set page_html "[ad_admin_header "Members of $user_class_name"]

<h2>Members of $user_class_name</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "User Classes"] [list "one.tcl?[export_url_vars user_class_id user_class_name]" "One Class"] "Members" ] 

<hr>

<ul>
"

db_foreach get_users_in_ec_user_class "select 
users.user_id, first_names, last_name, email,
m.user_class_approved_p
from users, ec_user_class_user_map m
where users.user_id = m.user_id
and m.user_class_id=:user_class_id" {

    append page_html "<li><a href=\"/admin/users/one?user_id=$user_id\">$first_names $last_name</a> ($email) "

    if { [ad_parameter UserClassApproveP ecommerce] } {
	append page_html "<font size=-1>[ec_decode $user_class_approved_p "t" "" "un"]approved</font> "
    }

    append page_html "(<a href=\"member-delete?[export_url_vars user_class_name user_class_id user_id]\">remove</a>"

    if { [ad_parameter UserClassApproveP ecommerce] } {
	if { $user_class_approved_p == "t" } {
	    append page_html " | <a href=\"approve-toggle?[export_url_vars user_class_id user_id user_class_approved_p]\">unapprove</a>"
	} else {
	    append page_html " | <a href=\"approve-toggle?[export_url_vars user_class_id user_id user_class_approved_p]\">approve</a>"
	}
    }

    append page_html ")\n"

} if_no_rows {

    append page_html "There are no users in this user class."
}

append page_html "</ul>

[ad_admin_footer]
"



doc_return  200 text/html $page_html