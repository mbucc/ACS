ad_page_contract {
    @cvs-id columns-view.tcl,v 3.1.2.8 2000/10/10 14:46:35 luke Exp
    @author Xian Ke xke@mit.edu
    This file should be called columns-view.tcl
    Called from columns-list.tcl
} {
    column_name:notnull
}

db_1row address_book_get_one_column_data "
    select column_name, extra_select, pretty_name, sort_order
    from address_book_viewable_columns 
    where column_name=:column_name"

#now we have the values from the database.

set page_content "
[ad_header "View the entry for $pretty_name"]

<h2>View the entry for $pretty_name</h2>

[ad_context_bar_ws [list "columns-list.tcl" "List of Columns"] "View a column"]

<hr>

<table>
<tr><th valign=top align=right>Column name in database:</th>
<td> $column_name </td></tr>

<tr><th valign=top align=right>Extra Select Statements (ie combinations)</th>
<td> <pre>[ns_quotehtml $extra_select]</pre> </td></tr>

<tr><th valign=top align=right>Pretty Name for Column:</th>
<td> $pretty_name </td></tr>

<tr><th valign=top align=right>Display order:</th>
<td> $sort_order </td></tr>

</table>
<ul>
<li><a href=\"columns-edit.tcl?[export_url_vars column_name]\">Edit the data for $pretty_name</a><br>
</ul>
<p>
[ad_footer]"



doc_return  200 text/html $page_content