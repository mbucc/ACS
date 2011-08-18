# $Id: one-user.tcl,v 3.0 2000/02/06 02:44:50 ron Exp $
#
# /admin/address-book/one-user.tcl
#
# by philg@mit.edu on November 1, 1999
#
# a modified version of /address-book/records.tcl
#  

set_the_usual_form_variables 0

# user_id
# maybe scope, maybe scope related variables (owner_id, group_id, on_which_group, on_what_id)
# note that owner_id is the user_id of the user who owns this module (when scope=user)


set db [ns_db gethandle]

set name [database_to_tcl_string $db "select first_names || ' ' || last_name from users where user_id=$user_id"]

append whole_page "
[ad_admin_header "All Records owned by $name" $db ]
<h2> Records owned by $name </h2>
 
[ad_admin_context_bar [list "index.tcl" "Address Book"] "One User"]

<hr>
"

append whole_page "<blockquote>\n"

set selection [ns_db select $db "select rowid
from address_book 
where user_id = $user_id 
order by upper(last_name), upper(first_names)"]
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append whole_page "[address_book_display_as_html [address_book_record_display $rowid "f"]]\n<p>\n"
}


append whole_page "

</blockquote>

[ad_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $whole_page
