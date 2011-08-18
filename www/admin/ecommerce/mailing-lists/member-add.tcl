# $Id: member-add.tcl,v 3.0 2000/02/06 03:18:44 ron Exp $
set_the_usual_form_variables
# category_id, subcategory_id, subsubcategory_id
# and either last_name or email

ReturnHeaders

ns_write "[ad_admin_header "Add Member to this Mailing List"]

<h2>Add Member to this Mailing List</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Mailing Lists"] "Add Member" ] 

<hr>
"

if { [info exists last_name] } {
    ns_write "<h3>Users whose last name contains '$last_name':</h3>\n"
    set last_bit_of_query "upper(last_name) like '%[string toupper $QQlast_name]%'"
} else {
    ns_write "<h3>Users whose email contains '$email':</h3>\n"
    set last_bit_of_query "upper(email) like '%[string toupper $QQemail]%'"
}

ns_write "<ul>
"

set db [ns_db gethandle]
set selection [ns_db select $db "select user_id, first_names, last_name, email
from users
where $last_bit_of_query"]

set user_counter 0
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    ns_write "<li><a href=\"member-add-2.tcl?[export_url_vars user_id category_id subcategory_id subsubcategory_id]\">$first_names $last_name</a> ($email)\n"
    incr user_counter
}

if { $user_counter == 0 } {
    ns_write "No such users were found.\n</ul>\n"
} else {
    ns_write "</ul>\n<p>Click on a name to add them to the mailing list.\n"
}

ns_write "[ad_admin_footer]
"
