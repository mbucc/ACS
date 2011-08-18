# $Id: in-category.tcl,v 3.1 2000/03/09 00:01:34 scott Exp $
set_form_variables

# category_id


set db [ns_db gethandle]
set selection [ns_db 1row $db "select unique category from categories where category_id='$category_id'"]
set_variables_after_query

append whole_page "<html>
<head><title>$category Users</title></head>
<body bgcolor=#ffffff text=#000000>
<h2>CogNet Users Interested in 
<A HREF=category.tcl?category_id=$category_id>$category</A></h2>

<ul>"


set selection [ns_db select $db "select u.*
from users u, users_interests ui, categories c
where u.user_id = ui.user_id
and ui.category_id = c.category_id 
and c.category_id = '$category_id'
order by u.last_name, u.first_names"]

while {[ns_db getrow $db $selection]} {
	set_variables_after_query
	append whole_page "<li><a href=\"users/1.tcl?user_id=$user_id\">$first_names $last_name ($email)</a>\n"
}


append whole_page "

</ul>


<address><a href=\"mailto:philg@mit.edu\">philg@mit.edu</a></address>

</body>
</html>
"
ns_db releasehandle $db
ns_return 200 text/html $whole_page
