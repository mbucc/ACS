# /www/search/search.tcl
ad_page_contract {
    Searches the site

    @author phong@arsdigita.com
    @creation-date 2000-08-01
    @cvs-id search.tcl,v 3.3.2.10 2000/09/22 01:39:17 kevin Exp
} {
    query_string:optional
    sections:multiple,optional
    {rows 0}
}

# do some error checking
set exception_text ""
set exception_count 0

if { ![info exists sections] || [llength $sections] == 0 } {
    ad_return_error "Configuration Error" "You must specify at least one section of [ad_system_name] to search. This is an error in your ACS configuration. Please see the <a href=\"/doc/site-wide-search\">site-wide search documentation</a> for more details.\n"
    return
}
if { ![info exists query_string] || [empty_string_p [string trim $query_string]] } {
    append exception_text "<li>You didn't specify a query to search for.\n"
    incr exception_count
}
if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

# get user search preferences
set display [ad_get_client_property -browser t -default "one_list" "search" "display_by_section_or_one_list"]
set num_results [ad_get_client_property -browser t -default "50" "search" "num_of_results_to_display"]
if { $rows != 0 } { set num_results $rows }
if { $num_results == 0 || $num_results == "all"} {
    set rowcount_clause ""
} else {
    set rowcount_clause "and RowNum <= $num_results"
}

# get the user_id
set user_id [ad_verify_and_get_user_id]
set group_list [db_list get_group_list "select group_id from user_group_map where user_id=:user_id"]
set is_authorized_p [im_user_is_authorized_p $user_id]

# this makes sure that the user didn't add 
# unauthorized tables to search from in the url
set sections [ad_sws_return_valid_tables $sections]

# create a string to export sections list
set sections_string ""
foreach s $sections {
    append sections_string "&sections=$s"
}

set results_base_url [ad_parameter BounceResultsTo site-wide-search ""]

# Restrict to selected sections.
set n_sections [llength $sections]


set file_p 0
set no_other 0
# Technically, Oracle can handle in clauses with a single value,
# but that's just not kosher ANSI.
if { $n_sections == 1 } {
    if { $sections == "fs_versions" } {
	set sections_clause "and sws.table_name = ''"
	set file_p 1
	set no_other 1
    } else {
	set sections_clause "and sws.table_name = '$sections'"
    }
} else {
    set quoted_sections [list]
    foreach s $sections {
	if {$s != "fs_versions" } {
	    lappend quoted_sections "'[DoubleApos $s]'"
	} else {
	    set file_p 1
	} 
    }
    set sections_clause "and sws.table_name in ([join $quoted_sections ", "])"
}

set final_query_string [DoubleApos [db_string final_query_select "select im_convert('[string trim [DoubleApos $query_string]]') from dual"]]

if { $display != "by_section"} {
    # Generic Search
    with_catch errmsg {
	# to do: move this catch to the db_foreach
	set sql "select /*+ FIRST_ROWS */ score(10) as the_score, 
                        section_name, 
                        user_url_stub, 
                        the_key, 
                        one_line_description, 
                        sws.table_name,
                        RowNum
	from site_wide_index sws, sws_properties p
	where sws.table_name = p.table_name 
        and contains(sws.datastore, '({[string trim [DoubleApos $query_string]]} within oneline)*6, $final_query_string', 10) > 0
	and sws_general_permissions(sws.user_id, sws.group_id, sws.scope, $user_id)='t'
	$rowcount_clause
	$sections_clause
	order by 1 desc"
    } {
	ad_return_error "Problem with interMedia" "There was a problem with interMedia 
	while processing your query. This site wide search thing is still somewhat experimental,
	so please bear with us while we work out the kinks. You may have better luck if you change
	your query a little bit.<br>"
	return
    }

    set search_results "" 
    set results_base_url [ad_parameter BounceResultsTo site-wide-search ""]
    set counter 0    
    db_foreach search_select $sql {
	incr counter			
	set one_line "<li><a href=\"$results_base_url$user_url_stub$the_key\">$one_line_description</a>\n"
	if { $n_sections > 1 && $display == "one_list" } {
	    append search_results "$one_line <font size=-1>($section_name)</font>\n"
	} else {
	    append search_results $one_line
	}
	# LuisRodriguez@photo.net, June 2000
	# Make sure sections is first var in URL, otherwise MSIE 4.01 will turn "&sect"
	# into a multibyte char and thus mangle the URL
	# Take this out for now, since it doesn't work properly (phong@arsdigita.com 8-30-2000)
	# append search_results "<font size=-1>(<a href=\"query-by-example?[export_url_vars table_name the_key]$sections_string&subject=[ns_urlencode $one_line_description]\">more like this</a>)</font>\n"
    }

    if { [empty_string_p $search_results] } {
	set search_results "No hits found for your query."
    }
    set results_displayed $counter

} else {
    # This is a by section wedge, so we can optimize this
    # Instead of going through the whole table row by row, we can constrain it
    # to each section, then perform multiple queries, which actually go faster
    # because we are only interested in the top few.

    set results_displayed 0
    set search_results ""
    foreach s $sections {
	with_catch errmsg {
	    if { $s == "fs_versions" } {
		set sql "SELECT /*+ FIRST_ROWS */ SCORE(10) AS the_score, section_name, user_url_stub, f.file_id as the_key, f.file_title as one_line_description, RowNum 
		              from fs_files f, fs_versions v, sws_properties sws
                              where v.file_id=f.file_id
                              and sws.table_name='$s'
	                      and deleted_p='f'
                              and contains(v.version_content,'$final_query_string',10)>0  
                              $rowcount_clause
                              order by 1 desc"
	    } else {
		set sql "select /*+ FIRST_ROWS */ score(10) as the_score, section_name, user_url_stub, the_key, one_line_description, sws.table_name, RowNum
		              from site_wide_index sws, sws_properties p
     	                      where sws.table_name = p.table_name
                              and p.table_name='$s' 
		and contains(sws.datastore, '({[string trim [DoubleApos $query_string]]} within oneline)*6, $final_query_string', 10) > 0
	                      and sws_general_permissions(user_id,group_id,scope,$user_id)='t'
	                      $rowcount_clause
	                      order by 1 desc"
	    }
	} {
	    ad_return_error "Problem with interMedia" "There was a problem with interMedia 
	    while processing your query. This site wide search thing is still somewhat experimental,
	    so please bear with us while we work out the kinks. You may have better luck if you change
	    your query a little bit."
	    return
	}
	
	set counter 0
	db_foreach modified_search_select $sql {
	    incr counter
	    incr results_displayed

	    if { $counter == 1 } {
		append search_results "<h3>$section_name</h3>\n"
	    }
	    if { $sections != "static_pages" || ![info exists static_url] || [empty_string_p $static_url] } {
		set static_url $user_url_stub
	    } 
	    if { $s == "fs_versions" } {
		append search_result "<li><a href=\"$results_base_url$user_url_stub$file_id\">$one_line_description</a>\n"
	    } elseif { $s != "static_pages" || $is_authorized_p || [ad_access_check $static_url ] } {
		append search_results "<li><a href=\"$results_base_url$user_url_stub$the_key\">$one_line_description</a>\n"
		# Take this out for now, since it doesn't work properly (phong@arsdigita.com 8-30-2000)
		# append search_results "<font size=-1>(<a href=\"query-by-example.tcl?[export_url_vars table_name the_key]$sections_string&subject=[ns_urlencode $one_line_description]\">more like this</a>)</font>\n"
	    }
	}
    }
    if { $results_displayed == 0 } {
	append search_results "No hits found for your query."
    }
}

# get the total number of hits
#set sql_query "select count(1)
#               from site_wide_index sws
#               where contains(sws.datastore, '({[string trim [DoubleApos $query_string]]} within oneline)*6, $final_query_string', 10) > 0
#	             and sws_general_permissions(sws.user_id, sws.group_id, sws.scope, $user_id)='t'
#                     $sections_clause"
#set total_num_results [db_string get_num_results $sql_query]
#Displaying [util_commify_number $results_displayed] results out of [util_commify_number $total_num_results] for \"$query_string\":

# keep track of what users search for
ad_record_query_string $query_string $sections $results_displayed $user_id


db_release_unused_handles

set page_content "
[ad_header "Search Results"]
<h2>Search Results</h2>
[ad_context_bar_ws_or_index [list "index" "Search"] "Results"]
<hr>

Search [ad_system_name]<br>
[ad_site_wide_search_widget $query_string]

[ad_sws_show_num_results_bar $num_results $display $query_string $sections_string]
<br><br>


<ul>
$search_results
</ul>

<a href=\"advanced-search?[export_url_vars query_string]\">Advanced Search</a>
[ad_footer]
"

doc_return  200 text/html $page_content





