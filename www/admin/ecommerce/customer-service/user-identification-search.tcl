# $Id: user-identification-search.tcl,v 3.0 2000/02/06 03:18:31 ron Exp $
set_the_usual_form_variables
# keyword

set page_title "Unregistered User Search"
ReturnHeaders

ns_write "[ad_admin_header $page_title]
<h2>$page_title</h2>

[ad_admin_context_bar [list "../index.tcl" "Ecommerce"] [list "index.tcl" "Customer Service Administration"] $page_title]

<hr>
<ul>
"

set db_pools [ns_db gethandle [philg_server_default_pool] 2]
set db [lindex $db_pools 0]
set db_sub [lindex $db_pools 1]

# keyword can refer to email, first_names, last_name, postal_code, or other_id_info

set selection [ns_db select $db "select user_identification_id from ec_user_identification
where (lower(email) like '%[string tolower $keyword]%' or lower(first_names || ' ' || last_name) like '%[string tolower $keyword]%' or lower(postal_code) like '%[string tolower $keyword]%' or lower(other_id_info) like '%[string tolower $keyword]%')
and user_id is null
"
]

set user_counter 0
while { [ns_db getrow $db $selection] } {
    incr user_counter
    set_variables_after_query
    ns_write "<li>[ec_user_identification_summary $db_sub $user_identification_id]"
}

if { $user_counter == 0 } {
    ns_write "No users found."
}

ns_write "</ul>
[ad_admin_footer]
"
