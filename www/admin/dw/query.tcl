#www/dw/query.tcl

ad_page_contract {
    Display information about the query. Allow user to execute the query or add new column to the query.
    
    @author Philip Greenspun (philg@mit.edu)
    @creation-date ?

    @param query_id a unique id identifies query
    @cvs-id query.tcl,v 1.1.2.2 2000/09/22 01:34:46 kevin Exp
} {
    {query_id:notnull,naturalnum}
}

set sql {select query_name, definition_time, query_sql, first_names || ' ' || last_name as query_owner 
from queries, users
where query_id = :query_id
and query_owner = users.user_id}

set select [db_0or1row dw_query_get_query_name $sql]

set page_content "
[ad_header "[ns_quotehtml $query_name]"]

<h2>[ns_quotehtml $query_name]</h2>

defined by $query_owner on [util_IllustraDatetoPrettyDate $definition_time]

<hr>
<ul>
<li><a href=\"query-execute?query_id=$query_id\">Execute immediately</a>
</ul>

Here's what query execution would do right now...
"

if ![empty_string_p $query_sql] {
    # user has hand-edited the SQL 
    append page_content "<blockquote>
<code><pre>
$query_sql

<a href=\"query-edit-sql?query_id=$query_id\">(edit)</a>
</pre></code>
</blockquote>
"
} else {
    # look at the query_columns table
    append page_content "<ul>"

    set sql  {select query_columns.*, rowid
              from query_columns
              where query_id = :query_id
              order by what_to_do}

    db_foreach dw_query_get_plan $sql {
	append page_content "<li>$column_name : "
	if { $what_to_do == "select_and_aggregate" } {
	    append page_content "select and aggregate using $value1"
	}
	if { $what_to_do == "select_and_group_by" } {
	    append page_content "select and group by"
	}
	if { $what_to_do == "restrict_by" } {
	    append page_content "limit to $value2 \"$value1\""
	}
	if { $what_to_do == "order_by" } {
	    append page_content "order by"
	}
	if ![empty_string_p $pretty_name] {
	    append page_content " (with a heading of \"$pretty_name\")"
	}
	#rowid is a reserve word in Oracle, need to change it to row_id
	set row_id $rowid
	append page_content " <a href=\"query-delete-column?[export_url_vars query_id row_id]\">delete</a> \n"
    } if_no_rows {
	append page_content "actually we've not got any plans yet"
    }

    append page_content "

<P>

<li><a href=\"query-add-column?query_id=$query_id\">add a column</a>

</ul>
"
}

# we're done explaining what the query will do 

append page_content [ad_footer]


doc_return  200 text/html $page_content















