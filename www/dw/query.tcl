# $Id: query.tcl,v 3.0 2000/02/06 03:38:53 ron Exp $
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
[ad_header "$query_name"]

<h2>$query_name</h2>

defined by $query_owner on [util_IllustraDatetoPrettyDate $definition_time]

<hr>

<ul>
<li><a href=\"query-execute.tcl?query_id=$query_id\">Execute immediately</a>
</ul>

Here's what query execution would do right now...

"

if ![empty_string_p $query_sql] {
    # user has hand-edited the SQL 
    ns_write "<blockquote>
<code><pre>
$query_sql

<a href=\"query-edit-sql.tcl?query_id=$query_id\">(edit)</a>
</pre></code>
</blockquote>
"
} else {
    # look at the query_columns table
    ns_write "
<ul>

"

    set selection [ns_db select $db "select query_columns.*, rowid
from query_columns
where query_id = $query_id
order by what_to_do"]
set counter 0

    while { [ns_db getrow $db $selection] } {
	set_variables_after_query
	incr counter
	ns_write "<li>$column_name : "
	if { $what_to_do == "select_and_aggregate" } {
	    ns_write "select and aggregate using $value1"
	}
	if { $what_to_do == "select_and_group_by" } {
	    ns_write "select and group by"
	}
	if { $what_to_do == "restrict_by" } {
	    ns_write "limit to $value2 \"$value1\""
	}
	if { $what_to_do == "order_by" } {
	    ns_write "order by"
	}
	if ![empty_string_p $pretty_name] {
	    ns_write " (with a heading of \"$pretty_name\")"
	}
	ns_write " <a href=\"query-delete-column.tcl?[export_url_vars query_id rowid]\">delete</a> \n"
    }

    if { $counter == 0 } {
	ns_write "actually we've not got any plans yet"
    }

    ns_write "

<P>

<li><a href=\"query-add-column.tcl?query_id=$query_id\">add a column</a>

</ul>
"
}

# we're done explaining what the query will do 

ns_write [ad_footer]
