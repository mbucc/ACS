# $Id: index.tcl,v 3.0 2000/02/06 02:44:50 ron Exp $
#
# /admin/address-book/index.tcl
#
# by philg@mit.edu on November 1, 1999
# 
# shows who is using the address book system
#

set db [ns_db gethandle]


ReturnHeaders

ns_write "
[ad_admin_header "Address Book"  ]
<h2>Address Book</h2>
 
[ad_admin_context_bar "Address Book"]

<hr>

Documentation:  <a href=\"/doc/address-book.html\">/doc/address-book.html</a>
<br>
User pages:  <a href=\"/address-book/\">/address-book/</a>

<p>

These are the users of [ad_system_name] who are using the address book
module:

<ul>
"


set selection [ns_db select $db "select users.user_id, users.first_names, users.last_name, count(*) as n_records
from users, address_book
where users.user_id = address_book.user_id
group by users.user_id, users.first_names, users.last_name"]

set items ""
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append items "<li><a href=\"/admin/users/one.tcl?[export_url_vars user_id]\">$first_names $last_name</a>:  
<a href=\"one-user.tcl?[export_url_vars user_id]\">$n_records</a>
"
}

if [empty_string_p $items] {
    ns_write "no users currently have any address records"
} else {
    ns_write $items
}

ns_write "

</ul>

[ad_admin_footer]
"

