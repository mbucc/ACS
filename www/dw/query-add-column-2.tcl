# $Id: query-add-column-2.tcl,v 3.0 2000/02/06 03:38:36 ron Exp $
set_the_usual_form_variables

# query_id, column_name, what_to_do

set exception_count 0
set exception_text ""

if { ![info exists column_name] || [empty_string_p $column_name] } {
    incr exception_count
    append exception_text "<li>You must pick a column.\n"
}

if { ![info exists what_to_do] || [empty_string_p $what_to_do] } {
    incr exception_count
    append exception_text "<li>You have to tell us what you want done with the column.\n"
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

ReturnHeaders

set db [ns_db gethandle] 

ns_write "
[ad_header "Add $column_name"]

<h2>Add $column_name</h2>

to <a href=\"query.tcl?query_id=$query_id\">[database_to_tcl_string $db "select query_name from queries where query_id = $query_id"]</a>

<hr>

<form method=POST action=\"query-add-column-3.tcl\">
[export_form_vars query_id column_name what_to_do]
"

if { $what_to_do == "select_and_aggregate" } {
    ns_write "Pick an aggregation method for $column_name : <select name=value1> 
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
    ns_write "If you don't wish your report to be headed by
\"$column_name\", you can choose a different title:
<input type=text name=pretty_name size=30>
<P>
"
}

if { $what_to_do == "restrict_by" } {
    ns_write "Restrict reporting to sales where $column_name
<select name=value2>
<option>=</option>
<option value=\">\">&gt;</option>
<option value=\"<\">&lt;</option>
</select>
<input type=text size=15 name=value1>\n"
}


ns_write "

<br>
<br>

<center>
<input type=submit value=\"Confirm\">
</center>
</form>
[ad_footer]
"
