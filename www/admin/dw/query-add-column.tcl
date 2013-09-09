# /www/dw/query-add-column.tcl

ad_page_contract {
    First page of adding new column. Gather column name and property from user.
    
    @author Phil Greenspun (philg@mit.edu)
    @creation-date ?
    @param query_id an unique ide identifies a query
    @cvs-id query-add-column.tcl,v 1.1.2.2 2000/09/22 01:34:43 kevin Exp
} {
    {query_id:naturalnum,notnull}
}

set selection [db_0or1row dw_add_column_get_query_name {select query_name from queries where query_id = :query_id}]
if {$selection == 0} {
    ad_return_error "Invalid query id" "Query could not be found."
    db_release_unused_handles
    return
}

set page_content "
[ad_header "Add Column"]

<h2>Add Column</h2>

to <a href=\"query?query_id=$query_id\">[ns_quotehtml $query_name]</a>

<hr>

<form method=POST action=\"query-add-column-2\">
[export_form_vars query_id]
<table>
<tr><th>Which Column<th>What to do with it</tr>
<tr>
<td>
<select name=column_name size=8>
"

set list_of_lists [dw_table_columns [dw_table_name]]

foreach sublist $list_of_lists {
    append page_content "<option>[lindex $sublist 0]\n"
}

append page_content "
</select>
<td>
<select name=what_to_do size=5>
<option value=\"select_and_group_by\">Select and Group By
<option value=\"select_and_aggregate\">Select and Aggregate (sum or average)
<option value=\"restrict_by\">Restrict By
<option value=\"order_by\">Order By
<option value=\"subtotal_when_changes\">Subtotal when changes

</select>
</tr>
</table>
<center>
<input type=submit value=\"Proceed\">
</center>
</form>

[ad_footer]
"

doc_return  200 text/html $page_content







