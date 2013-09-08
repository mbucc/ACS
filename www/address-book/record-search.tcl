# /www/address-book/record-search.tcl

ad_page_contract {

    @param scope
    @param user_id
    @param group_id
    @param return_url
    @param search_by
    @param search_value

    @creation-date 12/24/99
    @author teadams@arsdigita.com
    @author tarik@arsdigita.com
    @cvs-id record-search.tcl,v 3.1.6.15 2000/10/10 14:46:36 luke Exp

    Purpose:  shows a single address book record
} {
    scope:optional
    user_id:optional,integer
    group_id:optional,integer
    return_url:optional
    search_by
    search_value
}

ad_scope_error_check user

ad_scope_authorize $scope none group_member user

set name [address_book_name]

set page_content "
[ad_scope_header "Address Book Search Results"]
[ad_scope_page_title "Address Book Search Results"]

[ad_scope_context_bar_ws [list "index?[export_url_scope_vars return_url]" "Address book"] "Search"]
<hr>
[ad_scope_navbar]

<ul>
"

set result_string ""

db_foreach address_book_search_results "
select first_names, last_name, city, usps_abbrev, address_book_id 
from address_book 
where [ad_scope_sql] 
and upper($search_by) like '%[string toupper $search_value]%'" { 
    append result_string "<li>$first_names $last_name ($city, $usps_abbrev): <a href=\"record?[export_url_scope_vars address_book_id]&contact_info_only=f\">all info</a> | <a href=\"record?[export_url_scope_vars address_book_id]&contact_info_only=t\">contact info only</a><p>"
} if_no_rows {
    append result_string "<li>No records meet your criteria"
}

append page_content "
$result_string
</ul>
[ad_scope_footer]
"



doc_return  200 text/html $page_content