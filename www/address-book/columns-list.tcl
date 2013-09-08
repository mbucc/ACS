ad_page_contract {
    @cvs-id columns-list.tcl,v 3.1.2.11 2000/10/10 14:46:34 luke Exp
    Code for columns-list.tcl
} {
}

set page_content "[ad_header "Address Book Viewable Columns" ]
<h2>Address Book Viewable Columns</h2>


[ad_context_bar_ws [list "" "Address book"] "Viewable Columns"]


<hr>

<h3>All the columns</h3>
<ol>"


db_foreach address_book_get_pretty_names  "select pretty_name, 
column_name from address_book_viewable_columns order by sort_order" {
    append page_content "<li><a href=\"columns-view?[export_url_vars column_name]\">$pretty_name</a><br>"
} if_no_rows {
    append page_content "<li>There are no columns in the database right now.<p>"
}

append page_content "<p><li><a href=columns-add>Add a column</a></ul><p>
[ad_footer]"

doc_return  200 text/html $page_content





