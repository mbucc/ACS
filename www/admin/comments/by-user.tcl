# $Id: by-user.tcl,v 3.0 2000/02/06 03:14:52 ron Exp $
ReturnHeaders

ns_write "[ad_admin_header "Comments by user"]

<h2>Comments by user</h2>

[ad_admin_context_bar [list "index.tcl" "Comments"] "By Page"]

<hr>
 
<ul>
"

set db [ns_db gethandle]

set selection [ns_db select $db "select comments.user_id,  first_names, last_name, count(comments.page_id) as n_comments, sum(decode(comments.deleted_p,'t',1,0)) as n_deleted
from comments, users
where comments.user_id = users.user_id
group by comments.user_id, first_names, last_name
order by n_comments desc, upper(last_name), upper(first_names)"]


set items ""
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    append items "<li><a href=\"/admin/users/one.tcl?user_id=$user_id\">$first_names $last_name</a> ($n_comments"
    if { $n_deleted > 0 } {
	append items "; <font color=red>$n_deleted deleted</font>"
    }
    append items ")\n"
}
 
ns_write "$items
</ul>

[ad_admin_footer]
"
