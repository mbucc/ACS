ad_page_contract {
    index.tcl,v 3.2.2.3 2000/07/21 03:55:59 ron Exp
    
    /admin/address-book/index.tcl
    
    by philg@mit.edu on November 1, 1999
    
    shows who is using the address book system
} {
}


ReturnHeaders

ns_write "
[ad_admin_header "Address Book"  ]
<h2>Address Book</h2>
 
[ad_admin_context_bar "Address Book"]

<hr>

Documentation:  <a href=\"/doc/address-book\">/doc/address-book.html</a>
<br>
User pages:  <a href=\"/address-book/\">/address-book/</a>

<p>

These are the users of [ad_system_name] who are using the address book
module:

<ul>
"
set items ""
db_foreach address_book_admin_index "select users.user_id,
 users.first_names, users.last_name, count(*) as n_records
from users, address_book
where users.user_id = address_book.user_id
group by users.user_id, users.first_names, users.last_name" {
    append items "<li><a href=\"/admin/users/one?[export_url_vars user_id]\">$first_names $last_name</a>:  
<a href=\"one-user?[export_url_vars user_id]\">$n_records</a>
"
} if_no_rows {
    ns_write "no users currently have any address records"
} 

if {![empty_string_p $items]} {
    ns_write $items
}

ns_write "

</ul>

[ad_admin_footer]
"

db_release_unused_handles