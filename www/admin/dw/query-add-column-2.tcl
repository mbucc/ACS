#/www/dw/query-add-column-2.tcl
ad_page_contract {

    Get extra information base on the property for the new column.

    @author Philip Greenspun (philg@mit.edu)
    @creation-date ?
    @param query_id a unique id identifies a query
    @param column_name a new column name
    @param what_to_do property of this column
    @cvs-id query-add-column-2.tcl,v 1.1.2.2 2000/09/22 01:34:43 kevin Exp
    
} {
    {query_id:naturalnum,notnull}
    {column_name:sql_identifier,notnull,trim}
    {what_to_do:notnull,trim}
}
    
set page_content "
[ad_header "Add [ns_quotehtml $column_name]"]

<h2>Add [ns_quotehtml $column_name]</h2>

to <a href=\"query?query_id=$query_id\">[db_string dw_add_column_2_get_query_name {select query_name from queries where query_id = :query_id}]</a>

<hr>

<form method=POST action=\"query-add-column-3\">
[export_form_vars query_id column_name what_to_do]
"

if { $what_to_do == "select_and_aggregate" } {
    append page_content "Pick an aggregation method for $column_name : <select name=value1> 
<option>sum
<option>avg
<option>max
<option>min
<option>count
</select>
<p>
"
}

if { $what_to_do == "select_and_group_by" || $what_to_do == "select_and_aggregate" } {
    append page_content "If you don't wish your report to be headed by
\"$column_name\", you can choose a different title:
<input type=text name=pretty_name size=30>
<P>
"
}

if { $what_to_do == "restrict_by" } {
    append page_content "Restrict reporting to sales where $column_name
<select name=value2>
<option>=</option>
<option value=\">\">&gt;</option>
<option value=\"<\">&lt;</option>
</select>
<input type=text size=15 name=value1>\n"
}

append page_content "

<br>
<br>

<center>
<input type=submit value=\"Confirm\">
</center>
</form>
[ad_footer]
"


doc_return  200 text/html $page_content