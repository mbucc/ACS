#
# /www/admin/education/textbooks.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu
#
# this lists all of the textbooks used by the system
#

ad_page_variables {
    {order_by title}
}


set db [ns_db gethandle]

set return_string "
[ad_admin_header "[ad_system_name] Administration"]
<h2>Education Administration</h2>

[ad_context_bar_ws [list "/admin/" "Admin Home"] [list "" "Education Administration"] Textbooks]

<hr>
<blockquote>
"

set header "<table><tr>"

if {[string compare $order_by title] == 0} {
    set order_by "lower(title)"
    append header "<th>Title</th>"
} else {
    append header "<th><a href=\"textbooks.tcl?order_by=title\">Title</a></th>"
}

if {[string compare $order_by author] == 0} {
    set order_by "lower(author)"
    append header "<th>Author</th>"
} else {
    append header "<th><a href=\"textbooks.tcl?order_by=author\">Author</a></th>"
}

if {[string compare $order_by n_classes] == 0} {
    set order_by "count(class_id)"
    append header "<th>Number of Classes</th>"
} else {
    append header "<th><a href=\"textbooks.tcl?order_by=n_classes\">Number of Classes</a></th>"
}

append header "</tr>"

set order_by "lower(title)"

set selection [ns_db select $db "select books.textbook_id,
      count(class_id) as n_classes,
      title,
      author
 from edu_textbooks books,
      edu_classes_to_textbooks_map map
where books.textbook_id = map.textbook_id(+)
group by title, author, books.textbook_id
order by $order_by"]

set count 0

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    if {$count == 0} {
	append return_string "$header"
    }

    append return_string "
    <tr>
    <td>
    <a href=\"textbook-info.tcl?textbook_id=$textbook_id\">$title</a>
    </td>
    <td>
    $author
    </td>
    <td align=center>
    $n_classes
    </td>
    </td>
    "

    incr count
}


if {$count > 0} {
    append return_string "</table>"
} else {
    append return_string "There are currently no books used by any of the classes."
}

append return_string "
</blockquote>
[ad_admin_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $return_string
