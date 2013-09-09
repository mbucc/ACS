#/www/dw/query-execute.tcl

ad_page_contract {
    Execute the query and return data in table format.
    
    @author Philip Greenspun (philg@mit.edu)
    @creation-date ?
    @param query_id an unique id identifies query
    @cvs-id query-execute.tcl,v 1.1.2.2 2000/09/22 01:34:45 kevin Exp
} {
    {query_id:notnull,naturalnum}
}

set selection [db_0or1row dw_query_execute_get_name {select query_name, 
                                           definition_time, 
                                           query_sql, 
                                           first_names || ' ' || last_name as query_owner 
                                    from queries, users
                                    where query_id = :query_id
                                    and query_owner = users.user_id}]


if {$selection == 0} {
    ad_return_error "Invalid query id" "Invalid query id or this user doesn't own this query."
    db_release_unused_handles
    return
}

set page_content "[ad_header "Executing [ns_quotehtml $query_name]"]

<h2>Executing</h2>

<a href=\"query?query_id=$query_id\">[ns_quotehtml $query_name]</a> defined by $query_owner on [util_IllustraDatetoPrettyDate $definition_time]

<hr>
"

if ![empty_string_p $query_sql] {
    set sql $query_sql 
    set edit_anchor "edit"
} else {
    append page_content "Let's build the SQL first...\n\n"

    set query_info [dw_build_sql $query_id]
    if { $query_info == 0 } {
	ad_return_error "No display column" "This query doesn't seem ready for prime time:no columns have been designated for selection"
	return
    }
    set sql [lindex $query_info 0]
    set select_list_items [lindex $query_info 1]
    set order_clauses [lindex $query_info 2]
    set edit_anchor "edit SQL directly"
}

append page_content "

<blockquote>
<code><pre>
$sql

<a href=\"query-edit-sql?query_id=$query_id\">($edit_anchor)</a>
</pre></code>
</blockquote>

<table border=1>
<tr>
"

set need_display_header 1
set invalid_sql [catch {db_foreach dw_query_display_result $sql -column_set selection {

    if {$need_display_header} {
	# Construct table header will all the column name. Only need to construct header one.
	set size [ns_set size $selection]	
	for {set i 0} {$i < $size} {incr i} {
	    set header [ns_set key $selection $i]
	    if { [info exists order_clauses] && [lsearch $order_clauses $header] == -1 } {
		# we're not already ordering by this column
		append page_content "<th><a href=\"query-add-order-by?query_id=$query_id&column_name=[ns_urlencode $header]\">$header</a></th>"
	    } else {
		append page_content "<th>$header</th>"
	    }
	}
	set need_display_header 0
    }
    append page_content "<tr>"
    for {set i 0} {$i < $size} {incr i} {
	append page_content "<td>[ns_set value $selection $i]</td>"
    }
    append page_content "</tr>\n"
}
	
append page_content "
</table>

[ad_footer]
"
}] 

if {$invalid_sql} {
    append page_content "<br>This query is not a SELECT statement or invalid SQL syntax."
    append page_content "</tr></table>[ad_footer]"
}


doc_return  200 text/html $page_content










