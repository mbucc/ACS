# /www/admin/address-book/one-user.tcl
ad_page_contract {
    a modified version of /address-book/records.tcl
    note that owner_id is the user_id of the user who owns this module 
    (when scope=user)

    @author philg@mit.edu
    @creation-date 1 Nov 1999
    @cvs-id one-user.tcl,v 3.2.2.6 2000/09/22 01:34:17 kevin Exp

    @param user_id the user whose address book we are going to view.
    
} {
    user_id:integer
    scope:optional
    owner_id:optional,integer
    group_id:optional,integer
    on_which_group:optional
    on_what_id:optional,integer
}


set name [db_string address_book_admin_get_names "select first_names || ' ' || last_name from users where user_id = :user_id"]

append whole_page "
[ad_admin_header "All Records owned by $name"]
<h2> Records owned by $name </h2>
 
[ad_admin_context_bar [list "index.tcl" "Address Book"] "One User"]

<hr>
"

append whole_page "<blockquote>\n"

set address_data [ns_set create]
db_foreach address_book_admin_get_addresses "
select first_names, last_name,
       email, email2, 
       line1, line2, 
       city, usps_abbrev, zip_code, country,
       phone_home, phone_work, phone_cell, phone_other, 
       birthday, birthmonth, birthyear, 
       notes
from   address_book 
where  user_id = :user_id
order by upper(last_name), upper(first_names)" -column_set address_data {

    append whole_page "[address_book_record_display $address_data "f"]\n<p>\n"
}

append whole_page "

</blockquote>

[ad_footer]
"



doc_return  200 text/html $whole_page
