# /tcl/site-wide-search-defs.tcl

ad_library {

    @creation-date late 1999
    @author jsc@arsdigita.com
    @author phong@arsdigita.com
    @cvs-id site-wide-search-defs.tcl,v 3.1.2.8 2000/08/25 23:11:16 phong Exp

}


ad_proc ad_sws_parse_sql_from {query table_name} {
    Parses through the from query for one line description. Determines the
    type of code to produce.
} {

    # first break up the query
    set temp_list [split $query ","]
    set table_name_list [list]

    # loop through and get the first element
    # this is to get rid to table aliases like "users u"
    foreach temp_table $temp_list {
	eval "set temp [list $temp_table]"
	lappend table_name_list [lindex $temp 0]
    }

    # only makes one reference to the table that we are indexing
    if { ([llength $table_name_list] == 1) && ([lindex $table_name_list 0] == "$table_name") } {
	# need to check that the user did not use an alias in the query
	# this will mess up the reformulating in the select portion
	if { [string tolower $query] == [string tolower $table_name] } {
	    return "normal"
	} else {
	    return "mutating"
	}

    } else {
	# if there is a reference to the table we are indexing or
	# a table view, then we must use the mutating code
	foreach temp_table $table_name_list {
	    set count [dbstring site_wide_search_parse_sql_from "select count(1) from user_views where view_name = upper(:temp_table)"]
	    if { ($count > 0) || ([string tolower $temp_table] == [string tolower $table_name]) } {
		return "mutating"
	    }
	}
	
	return "nonmutating"
    }
}

ad_proc ad_sws_generate_db_name { table column { max_length 30 } } {
    Returns the concatenation of table and column attached together by
    an underscore. Truncates this string to max_length.
} {
    set the_name "${table}_$column"
    if { [string length $the_name] <= $max_length } {
        return $the_name
    }
    set table_length [string length $table]
    set column_length [string length $column]
    set new_table_length [expr $max_length - $column_length - 1]
    if { $new_table_length > 0 } {
        set table [string range $table 0 [expr $new_table_length - 1]]
        return "${table}_$column"
    } else {
        return [string range $column 0 [expr $max_length - 1]]
    }
}

 
ad_proc ad_sws_get_num_of_pk { table_name } {
    Returns the number of primary keys for a table
} {
    set sql_query "
      select count(*)
      from user_cons_columns u1, user_constraints u2
      where u1.constraint_name=u2.constraint_name and
            u1.table_name=upper(:table_name) and
            u2.constraint_type='P'"
    return [db_string site_wide_search_get_num_of_pk $sql_query]
}


ad_proc ad_search_results_cutoff { nth_row current_score max_score } {
    Returns 1 to indicate that a search result should be cut off, based on
    a heuristic measure of current relevance vs. number of rows
    already returned.
} {
    if { ($nth_row > 25) && ($current_score < [expr 0.3 * $max_score] ) } {
	# we've gotten more than 25 rows AND our relevance score
	# is down to 30% of what the maximally relevant row was
	return 1
    }
    if { ($nth_row > 50) && ($current_score < [expr 0.5 * $max_score] ) } {
	# take a tougher look
	return 1
    }
    if { ($nth_row > 100) && ($current_score < [expr 0.8 * $max_score] ) } {
	# take a tougher look yet
	return 1
    }
    return 0
}

ad_proc ad_sws_show_num_results_bar { num_results display query_string sections_string} {
    Returns a link bar to select how many results to show
} {
    set result_list [list "20" "50" "100" "200" "all"]
    set widget "Show \[ "
    set counter 0
    foreach result $result_list {
	if { $counter > 0 } {
	    append widget " | "
	}
	if { $num_results == "$result" } {
	    append widget " $result "
	} else {
	    append widget "<a href=\"search?[export_url_vars query_string]$sections_string&rows=$result\">$result</a>"
	}
	incr counter
    }
    append widget " \]"
    if { $display == "by_section" } {
	append widget " results per section."
    } else {
	append widget " results per page."
    }
    return $widget
}

ad_proc ad_sws_return_valid_tables { sections } {
    Checks the sections list and makes sure that
    the user didn't add unauthorized tables to search
    from in the url. Returns a subset of tablenames
    in sections list that are valid.
} {
    # check if this user is authorized
    set user_id [ad_verify_and_get_user_id]
    set is_authorized_p [im_user_is_authorized_p $user_id]

    # get a list of searchable tables for the user
    set sql_query "select table_name from sws_properties"
    if { !$is_authorized_p } { append sql_query " where public_p='t'" }
    append sql_query " order by rank"

    set temp_sections [list]
    db_foreach get_valid_table_names $sql_query {
	if { [lsearch -exact $sections "$table_name"] != -1 } {
	    lappend temp_sections "$table_name"
	}
    }

    return $temp_sections
}

ad_proc ad_site_wide_search_widget { query_string } {
    Generates an html widget for the user to enter a query
} {
    # check if this user is authorized
    set user_id [ad_verify_and_get_user_id]
    set is_authorized_p [im_user_is_authorized_p $user_id]

    # get a list of searchable tables for the user
    set sql_query "select table_name, section_name from sws_properties"
    if { !$is_authorized_p } { append sql_query " where public_p='t'" }
    append sql_query " order by section_name"

    set widget "<form method=get action=\"/search/search\">\n"
    db_foreach get_table_names_for_widget $sql_query {
	append widget "<input type=hidden name=sections value=\"$table_name\">\n"
    }
    
    append widget "<input type=text size=20 name=query_string value=\"$query_string\">
                   <input type=submit value=\"Go\">
                   </form>"

    return $widget
}

ad_proc ad_search_display_preference {} {
    Returns "by_section" or "one_list" to indicate user's display preference
    for site wide search. Preference is stored in a cookie, or defaults to
    "by_section".
} {
    return "by_section"
}

# Helper function for ad_search_qbe_get_themes.
proc ad_search_qbe_get_themes_helper { table_name primary_key } {
    db_transaction {

    db_exec_plsql db_actions "begin :1 := 0; ctx_doc.themes('SWS_CTX_INDEX', ctx_doc.pkencode(:table_name, :primary_key), 'SWS_RESULT_TABLE', 1); end;"

    set count 0
    set themes [list]

    db_foreach sws_result {
	select theme
	from   sws_result_table
	order  by weight desc

    } {
	lappend themes $theme
	incr count
	if { $count == 5 } {
	    break
	}
    }

    db_dml site_wide_search_ad_search_qbe_get_themes_remove "delete from sws_result_table"
}
    return $themes
}

ad_proc ad_search_qbe_get_themes { table_name primary_key } {
    Return a list of themes associated with the document in the site wide index
    referenced by table_name and primary_key.
} {
    return [util_memoize "ad_search_qbe_get_themes_helper $table_name $primary_key"]
}





ad_proc ad_search_query_one_table {table_name final_query_string results_base_url user_id {authorized_or_static_p 1}} {
a proc for returning searching for a certain table <i>table_name</i>,<i>final_query_string</i>, is the string being searched, <i>user_id</i> is the connecting user id, and <i>authorized_or_static_p</i> is just sections=="static"||is_authorized_p==1
} {
    if { $table_name=="fs_versions"} {
	set  sql_query "SELECT /*+ FIRST_ROWS */ SCORE(10) AS the_score,FILE_TITLE,f.file_id,client_file_name
	                                 from fs_files f,fs_versions v
                                         where v.file_id=f.file_id
	                                 and deleted_p='f'
                                         and contains(version_content,'$final_query_string',10)>0  
                                         order by 1 desc"
	with_catch errmsg {
	    # to do: this catch should also go around the db_foreach
	    set sql $sql_query
	} {
	    ad_return_error "Problem with interMedia" "There was a problem with interMedia 
	    while processing your query. This site wide search thing is still somewhat experimental,
	    so please bear with us while we work out the kinks. You may have better luck if you change
	    your query a little bit."
	    return
	}
	
	set counter 0
	set max_score 0
	set search_results ""
	db_foreach modified_search_select $sql {
	    incr counter
	    set any_hits_p 1
	    
	    if { $counter == 1 } {
		set max_score $the_score
		append search_results "<h3>$section_name</h3>\n"
	    }
	    
	    if { [ad_search_results_cutoff $counter $the_score $max_score] } {
		# All done with current section
		break
	    }
	    append search_result "<li>$the_score: <a href=\"/file-storage/one-file?file_id=$file_id\">$file_title</a>\n"
	}
    } else {
	set sql_query "
	SELECT /*+ FIRST_ROWS */ SCORE(10) AS the_score, section_name, 
	user_url_stub, the_key, one_line_description, sws.table_name
	FROM site_wide_index sws, table_acs_properties m
	WHERE sws.table_name='$table_name'
	AND sws.table_name = m.table_name
	AND sws_general_permissions(user_id,group_id,scope,$user_id)='t'
	AND CONTAINS(sws.datastore, '$final_query_string', 10) > 0
	ORDER BY SCORE(10) DESC"
	
	with_catch errmsg {
	    # to do: this catch should also go around the db_foreach
	    set sql $sql_query
	} {
	    ad_return_error "Problem with interMedia" "There was a problem with interMedia 
	    while processing your query. This site wide search thing is still somewhat experimental,
	    so please bear with us while we work out the kinks. You may have better luck if you change
	    your query a little bit."
	    return
	}
	
	set counter 0
	set max_score 0
	set search_results ""
	db_foreach modified_search_select $sql {
	    incr counter
	    set any_hits_p 1
	    
	    if { $counter == 1 } {
		set max_score $the_score
		append search_results " <h3>$section_name</h3>\n"
	    }
	    
	    if { [ad_search_results_cutoff $counter $the_score $max_score] } {
		# All done with current section
		break
	    } 
	    
	    if { $authorized_or_static_p==1 || [ad_access_check $user_url_stub ] } {
		append search_results " <li>$the_score: <a href=\"$results_base_url$user_url_stub$the_key\">$one_line_description</a>\n"
		append search_results "<font size=-1>(<a href=\"query-by-example.tcl?[export_url_vars sections table_name the_key]&subject=[ns_urlencode $one_line_description]\">more like this</a>)</font>\n"
	    }
	}
    }
    return $search_results
}


