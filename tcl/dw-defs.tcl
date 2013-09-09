ad_library {
    Supporting procedures for data warehousing module

    @author Philip Greenspun (philg@mit.edu)
    @creation-date 12/25/1998
    @cvs-id dw-defs.tcl,v 3.2.2.3 2000/07/24 23:51:12 avni Exp

}

ad_register_filter preauth HEAD /dw/* dw_verify_user_is_admin
ad_register_filter preauth GET /dw/*  dw_verify_user_is_admin
ad_register_filter preauth POST /dw/* dw_verify_user_is_admin

proc_doc dw_verify_user_is_admin { conn args why} {Returns 1 if the user is either a site-wide administrator or in the dw administration group} {
    set user_id [ad_verify_and_get_user_id]
    
    if { $user_id == 0 } {
	# Not logged in
	ad_returnredirect "/register/index?return_url=[ns_urlencode [ns_conn url]?[ns_conn query]]"
	return filter_return
    }

    set val [dw_is_user_site_wide_or_dw_admin $user_id]

    if { $val > 0 } {
	return filter_ok
    } else {
	ad_return_forbidden "Access denied" "You must be an administrator of [ad_parameter SystemName] to see this page"
	return filter_return	
    }
}

proc_doc dw_is_user_site_wide_or_dw_admin { { user_id "" } } { Returns 1 if a user is a site-wide administrator or a member of the dw administrative group } {
    if { [empty_string_p $user_id] } {
	set user_id [ad_verify_and_get_user_id]
    }
    if { $user_id == 0 } {
	return 0
    }
    if { [dw_user_admin_p $user_id] } {
	# DW Administrator
	return 1
    } elseif { [ad_permission_p site_wide "" "" $user_id] } {
	# Site-Wide Administrator
	return 1
    } 
    return 0
}

proc_doc dw_user_admin_p {user_id} {
    returns 1 if the user is an intranet admin (ignores site-wide admin permissions)
} {
    return [ad_administration_group_member [ad_parameter UserGroupType dw dw] "" $user_id]
}    


proc_doc dw_table_name {} "Returns the name of the table that we typically use for data warehouse queries; may vary by user." {
    # you will probably want to edit this to run ad_verify_and_get_user_id
    # then return a particular view that is reasonable for that user
    return [ad_parameter DefaultTable dw "ad_hoc_query_view"]
}

proc dw_system_name {} {
    return [ad_parameter SystemName dw "[ad_system_name] data warehouse"]
}

proc_doc dw_table_columns {table} "Returns a list of lists, one for each column in a table.  Each sublist is a column name and a data type." {
    set list_of_columns [db_columns $table]

    set list_of_lits [list]
    foreach column $list_of_columns {
	set sublist [list $column [db_column_type $table $column]]
	lappend list_of_lists $sublist
    }

    return $list_of_lists
}

proc_doc dw_build_sql {query_id} "Returns the SQL code for a query, based on information in the query_columns table.  Returns a list of \$sql \$select_list_items \$order_clauses.    Returns 0 if there aren't enough columns specified to form a query." {
    set select_list_items [list]
    set group_by_items [list]

    set sql {select column_name, pretty_name
             from query_columns 
             where query_id = :query_id
                   and what_to_do = 'select_and_group_by'}

    db_foreach dw_defs_get_select_and_group_by $sql {
	if [empty_string_p $pretty_name] {
	    lappend select_list_items $column_name
	} else {
	    lappend select_list_items "$column_name as \"$pretty_name\""
	}
	lappend group_by_items $column_name
    }
    
    set sql {select column_name, pretty_name, value1
             from query_columns 
             where query_id = :query_id
                   and what_to_do = 'select_and_aggregate'}

    db_foreach dw_defs_get_select_and_aggregate $sql {
	if [empty_string_p $pretty_name] {
	    lappend select_list_items "${value1}($column_name)"
	} else {
	    lappend select_list_items "${value1}($column_name) as \"$pretty_name\""
	}
    }

    set sql {select column_name, value1, value2
             from query_columns 
             where query_id = :query_id
                   and what_to_do = 'restrict_by'}

    set where_clauses [list]

    db_foreach dw_defs_get_where_clause $sql {
	lappend where_clauses "$column_name $value2 '[DoubleApos $value1]'"
    }

    set sql {select column_name
             from query_columns 
             where query_id = :query_id
                   and what_to_do = 'order_by'}

    set order_clauses [list]

    db_foreach dw_defs_get_order_clauses $sql {
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


















































