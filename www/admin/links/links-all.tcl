# $Id: links-all.tcl,v 3.0 2000/02/06 03:24:44 ron Exp $
ReturnHeaders

ns_write "[ad_admin_header "All related links"]

<h2>All related links</h2>

in <a href=/admin/index.tcl>[ad_system_name]</a>

<hr>
 
Listing of all related links.

<ul>
"

set db [ns_db gethandle]


set selection [ns_db select $db "select links.link_title, links.link_description, links.url, links.status,  to_char(posting_time,'Month dd, yyyy') as posted,
users.user_id, first_names || ' ' || last_name as name 
from static_pages sp, links, users
where sp.page_id (+) = links.page_id
and users.user_id = links.user_id
order by posting_time asc"]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    
    ns_write "<li>$posted: <a href=\"$url\">$link_title</a> - $link_description (<font color=red>[string trim $status]</font>) posted by <a href=\"users/one.tcl?user_id=$user_id\">$name</a>   &nbsp; &nbsp; <a href=\"link-edit.tcl\">edit</a> &nbsp; &nbsp;  <a href=\"link-delete.tcl\">delete</a>"

}
 
ns_write "
</ul>

[ad_admin_footer]
"