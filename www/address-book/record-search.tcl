# $Id: record-search.tcl,v 3.0 2000/02/06 02:44:22 ron Exp $
# File:     /address-book/record-search.tcl
# Date:     12/24/99
# Contact:  teadams@arsdigita.com, tarik@arsdigita.com
# Purpose:  shows a single address book record
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

set_the_usual_form_variables 0
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)
# maybe return_url
# search_by, search_value

ad_scope_error_check user

set db [ns_db gethandle]
ad_scope_authorize $db $scope none group_member user

set name [address_book_name $db]

ReturnHeaders
ns_write "
[ad_scope_header "Address Book Search Results" $db]
[ad_scope_page_title "Address Book Search Results" $db]

[ad_scope_context_bar_ws [list "index.tcl?[export_url_scope_vars return_url]" "Address book"] "Search"]
<hr>
[ad_scope_navbar]

<ul>
"

set selection [ns_db select $db "
select first_names, last_name, city, usps_abbrev, address_book_id 
from address_book 
where [ad_scope_sql] 
and upper($search_by) like '%[string toupper $QQsearch_value]%'"]

set count 0
set result_string ""
while { [ns_db getrow $db $selection] } {
    set_variables_after_query

    incr count
    append result_string "<li>$first_names $last_name ($city, $usps_abbrev): <a href=\"record.tcl?[export_url_scope_vars address_book_id]&contact_info_only=f\">all info</a> | <a href=\"record.tcl?[export_url_scope_vars address_book_id]&contact_info_only=t\">contact info only</a><p>"
}

if {$count == 0} {
    append result_string "<li>No records meet your criteria"
}

ns_write "
$result_string
</ul>
[ad_scope_footer]
"

