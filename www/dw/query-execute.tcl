# $Id: query-execute.tcl,v 3.0 2000/02/06 03:38:49 ron Exp $
set_the_usual_form_variables

# query_id

set db [ns_db gethandle]

set selection [ns_db 1row $db "select query_name, definition_time, query_sql, first_names || ' ' || last_name as query_owner 
from queries, users
where query_id = $query_id
and query_owner = users.user_id"]
set_variables_after_query

ReturnHeaders

ns_write "
[ad_header "Executing $query_name"]

<h2>Executing</h2>

<a href=\"query.tcl?query_id=$query_id\">$query_name</a> defined by $query_owner on [util_IllustraDatetoPrettyDate $definition_time]

<hr>

"

if ![empty_string_p $query_sql] {
    set sql $query_sql 
    set edit_anchor "edit"
} else {
    ns_write "Let's build the SQL first...\n\n"

    set query_info [dw_build_sql $db $query_id]
    if { $query_info == 0 } {
	ns_write "This query doesn't seem ready for prime time:  no columns have been designated for selection"
	return
    }
    set sql [lindex $query_info 0]
    set select_list_items [lindex $query_info 1]
    set order_clauses [lindex $query_info 2]
    set edit_anchor "edit SQL directly"
}

ns_write "

<blockquote>
<code><pre>
$sql

<a href=\"query-edit-sql.tcl?query_id=$query_id\">($edit_anchor)</a>
</pre></code>
</blockquote>

<table border=1>
<tr>
"

set selection [ns_db select $db $sql]

set size [ns_set size $selection]
for {set i 0} {$i < $size} {incr i} {
    set header [ns_set key $selection $i]
    if { [info exists order_clauses] && [lsearch $order_clauses $header] == -1 } {
	# we're not already ordering by this column
	ns_write "<th><a href=\"query-add-order-by.tcl?query_id=$query_id&column_name=[ns_urlencode $header]\">$header</a></th>"
    } else {
	ns_write "<th>$header</th>"
    }
}

ns_write "</tr>\n"

# we're done showing the header

while { [ns_db getrow $db $selection] } {
    ns_write "<tr>"
    for {set i 0} {$i < $size} {incr i} {
	ns_write "<td>[ns_set value $selection $i]</td>"
    }
    ns_write "</tr>\n"
}

ns_write "
</table>


[ad_footer]
"
