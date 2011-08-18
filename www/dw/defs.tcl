# $Id: defs.tcl,v 3.0 2000/02/06 03:38:34 ron Exp $
# definitions that are useful for data warehousing
# defined by philg@mit.edu on December 25, 1998

# this is the biggest limitation of the system right here; you can 
# only really use it effectively if you can build one big view from all
# of your tables

proc_doc dw_table_name {} "Returns the name of the table that we typically use for data warehouse queries; may vary by user." {
    # you will probably want to edit this to run ad_verify_and_get_user_id
    # then return a particular view that is reasonable for that user
    return [ad_parameter DefaultTable dw "ad_hoc_query_view"]
}

proc dw_system_name {} {
    return [ad_parameter SystemName dw "[ad_system_name] data warehouse"]
}

proc_doc dw_table_columns {db table} "Returns a list of lists, one for each column in a table.  Each sublist is a column name and a data type." {
    set size [ns_column count $db $table]
    set list_of_lists [list]
    for {set i 0} {$i < $size} {incr i} {
	set sublist [list [ns_column name $db $table $i] [ns_column typebyindex $db $table $i]]
	lappend list_of_lists $sublist
    }
    return $list_of_lists
}

proc_doc dw_build_sql {db query_id} "Returns the SQL code for a query, based on information in the query_columns table.  Returns a list of \$sql \$select_list_items \$order_clauses.    Returns 0 if there aren't enough columns specified to form a query." {
    set select_list_items [list]
    set group_by_items [list]

    set selection [ns_db select $db "select column_name, pretty_name
    from query_columns 
    where query_id = $query_id
    and what_to_do = 'select_and_group_by'"]

    while { [ns_db getrow $db $selection] } {
	set_variables_after_query
	if [empty_string_p $pretty_name] {
	    lappend select_list_items $column_name
	} else {
	    lappend select_list_items "$column_name as \"$pretty_name\""
	}
	lappend group_by_items $column_name
    }

    set selection [ns_db select $db "select column_name, pretty_name, value1
    from query_columns 
    where query_id = $query_id
    and what_to_do = 'select_and_aggregate'"]

    while { [ns_db getrow $db $selection] } {
	set_variables_after_query
	if [empty_string_p $pretty_name] {
	    lappend select_list_items "${value1}($column_name)"
	} else {
	    lappend select_list_items "${value1}($column_name) as \"$pretty_name\""
	}
    }

    set selection [ns_db select $db "select column_name, value1, value2
    from query_columns 
    where query_id = $query_id
    and what_to_do = 'restrict_by'"]

    set where_clauses [list]

    while { [ns_db getrow $db $selection] } {
	set_variables_after_query
	lappend where_clauses "$column_name $value2 '[DoubleApos $value1]'"
    }


    set selection [ns_db select $db "select column_name
    from query_columns 
    where query_id = $query_id
    and what_to_do = 'order_by'"]

    set order_clauses [list]

    while { [ns_db getrow $db $selection] } {
	set_variables_after_query
	lappend order_clauses "$column_name"
    }

    if { [llength $select_list_items] == 0 } {
	return 0
    }

    set sql "SELECT [join $select_list_items ", "]
FROM [dw_table_name]\n"

    if { [llength $where_clauses] > 0 } {
	append sql "WHERE [join $where_clauses " AND "]\n"
    }

    if { [llength $group_by_items] > 0 } {
	append sql "GROUP BY [join $group_by_items ", "]\n"
    }

    if { [llength $order_clauses] > 0 } {
	append sql "ORDER BY [join $order_clauses ", "]"
    }

    return [list $sql $select_list_items $order_clauses]
}
