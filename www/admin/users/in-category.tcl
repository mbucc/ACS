ad_page_contract {
    @param category_id
    @author ?
    @creation-date ?
    @cvs-id in-category.tcl,v 3.3.2.3.2.5 2000/09/22 01:36:18 kevin Exp
} {
    category_id:integer,notnull
}


db_1row category_by_id "select unique category from categories where category_id = :category_id"

append whole_page "<html>
<head><title>$category Users</title></head>
<body bgcolor=#ffffff text=#000000>
<h2>CogNet Users Interested in 
<A HREF=category?category_id=$category_id>$category</A></h2>

<ul>"

set sql "select u.*
from users u, users_interests ui, categories c
where u.user_id = ui.user_id
and ui.category_id = c.category_id 
and c.category_id = :category_id
order by u.last_name, u.first_names"

db_foreach users_by_category $sql {
	append whole_page "<li><a href=\"users/1?user_id=$user_id\">$first_names $last_name ($email)</a>\n"
}

append whole_page "

</ul>

<address><a href=\"mailto:philg@mit.edu\">philg@mit.edu</a></address>

</body>
</html>
"



doc_return  200 text/html $whole_page
