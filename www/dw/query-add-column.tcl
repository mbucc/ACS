# $Id: query-add-column.tcl,v 3.0 2000/02/06 03:38:39 ron Exp $
set_the_usual_form_variables

# query_id 

ReturnHeaders

set db [ns_db gethandle] 

ns_write "
[ad_header "Add Column"]

<h2>Add Column</h2>

to <a href=\"query.tcl?query_id=$query_id\">[database_to_tcl_string $db "select query_name from queries where query_id = $query_id"]</a>

<hr>

<form method=POST action=\"query-add-column-2.tcl\">
[export_form_vars query_id]
<table>
<tr><th>Which Column<th>What to do with it</tr>
<tr>
<td>
<select name=column_name size=8>
"

set list_of_lists [dw_table_columns $db [dw_table_name]]

foreach sublist $list_of_lists {
    ns_write "<option>[lindex $sublist 0]\n"
}

ns_write "
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
