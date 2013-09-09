# tcl/curriculum.tcl
ad_library {
    documented in /doc/curriculum.html
    
    @cvs-id curriculum.tcl,v 3.3.2.4 2000/08/06 17:41:37 cnk Exp
    @author Philip Greenspun (philg@mit.edu*) 
    @creation-date September 25, 1999
}

ad_proc curriculum_get_output_cookie {} {Returns the value of the CurriculumProgress cookie that will be written to the client, or empty string if none is in the outputheaders ns_set} {
    if [empty_string_p [ns_conn outputheaders]] {
	return ""
    }
    set set_id [ns_conn outputheaders]
    for {set i 0} {$i<[ns_set size $set_id]} {incr i} {
	if { [string compare [ns_set key $set_id $i] "Set-Cookie"] == 0 } {
	    # it is a Set-Cookie header 
	    if { [regexp {CurriculumProgress=([^;]+)} [ns_set value $set_id $i] {} curriculum_progress] } {
		# it IS for the CurriculumProgress cookie
		return $curriculum_progress
	    }
	}
    }
    # if we got here, means we didn't find anything 
    return ""
}

ad_proc curriculum_bar {} {Returns a string containing the HTML for a curriculum bar.  Assumes the system is enabled but checks to see if this particular user should get one.} {
    # check cookie to make sure this person isn't finished
    if {[catch {set cookie [ns_set get [ns_conn headers] Cookie]}]} {
	# We trap for errors in case the connection has been 
	# closed (ns_conn will fail)
	set cookie ""
    }
    if { [regexp {CurriculumProgress=([^;]+)} $cookie {} input_cookie] } {
	# we have a cookie
	if { [string compare $input_cookie "finished"] == 0 } {
	    # user has completed curriculum, don't bother showing the bar 
	    return ""
	} else {
	    # compare what the user has seen to what is in the full curriculum
	    # to put in checkboxes; we check the output headers first and then 
	    # the input headers, in case there is going to be a newer value
	    set output_cookie [curriculum_get_output_cookie]
	    if { [empty_string_p $output_cookie] } {
		return [curriculum_bar_internal $input_cookie]
	    } else {
		return [curriculum_bar_internal $output_cookie]
	    }
	}
    } else {
	# no cookie; this person is either brand new or their browser is rejecting cookies
	# let's not uglify all their pages with a bar that they can't use
	return ""
    }
}

proc curriculum_bar_internal {cookie_value} {
    # cookie_value will either be "finished" or a Tcl list of integers
    set the_big_list [util_memoize "curriculum_bar_all_db_rows"]
    set table_elements [list]
    foreach sublist $the_big_list {
	set curriculum_element_id [lindex $sublist 0]
	set url [lindex $sublist 1]
	set very_very_short_name [lindex $sublist 2]
	if { [lsearch -exact $cookie_value $curriculum_element_id] == -1 } {
	    # user hasn't completed this part of the curriculum
	    set checkbox_url "/graphics/unchecked.gif"
	} else {
	    set checkbox_url "/graphics/checked.gif"
	}
	if ![empty_string_p [ad_parameter BarFontTag curriculum]] {
	    set complete_name "[ad_parameter BarFontTag curriculum]$very_very_short_name</font>"
	} else {
	    set complete_name $very_very_short_name
	}
	lappend table_elements "<td [ad_parameter CellExtraTags curriculum ""] valign=top><a href=\"/curriculum/clickthrough?[export_url_vars curriculum_element_id]\">$complete_name</a>
<br>
<center>
<a href=\"/curriculum/clickthrough?[export_url_vars curriculum_element_id]\"><img border=0 width=12 height=12 src=\"$checkbox_url\"></a>
</center>
</td>"
    }
    if { [llength $table_elements] == 0 } {
	# publisher hasn't established a curriculum
	return ""
    } else {
	# let's tack a help link at the end
	lappend table_elements "\n<td [ad_parameter CellExtraTags curriculum ""] valign=center><a href=\"/curriculum/\">[ad_parameter HelpAnchorText curriculum "?"]</a></td>"
	return "<table><tr>\n[join $table_elements "\n"]\n</tr></table>\n"
    }
}

# this is designed to be called within a memoization proc
proc curriculum_bar_all_db_rows {} {
    set the_big_list [db_list_of_lists curriculem_basic_info "select curriculum_element_id, url, very_very_short_name 
from curriculum
order by element_index"]
    return $the_big_list
}

ad_proc curriculum_progress_cookie_value {{old_value ""} {new_element ""}} {If not args are supplied, returns the initial value for the CurriculumProgress cookie.  If an old value and new element are supplied, returns an appropriate new cookie value.} {
    if { [empty_string_p $old_value] && [empty_string_p $new_element] } {
	return "start"
    } elseif { $old_value == "start" } {
	return [list $new_element]
    } elseif { $old_value == "finished" } {
	# if you're finished, adding a new element doesn't change that!
	return "finished"
    } else {
	set tentative_result [lappend old_value $new_element]
	if { [llength [util_memoize "curriculum_bar_all_db_rows"]] == [llength $tentative_result] } {
	    return "finished"
	} else {
	    return $tentative_result
	}
    }
}

ad_proc curriculum_sync {} {Looks at input cookie and looks in database.  Returns a new cookie to write to the browser.  Returns empty string if a new cookie isn't necessary.  Inserts rows into the database if necessary.  Assumes that there is a user logged in.} {
    set user_id [ad_get_user_id]
    set cookie [ns_set get [ns_conn headers] Cookie]
    if ![regexp {CurriculumProgress=([^;]+)} $cookie {} input_cookie] {
	# we had no cookie
	set input_cookie [list]
    }
    # initialize
    set new_cookie $input_cookie
    set new_cookie_necessary_p 0
    
    #This could be converted to a db_foreach, but we use it twice below.  
    set elts_from_database [db_list get_curr_ids "select curriculum_element_id from user_curriculum_map where user_id = :user_id"]

    foreach dbelt $elts_from_database {
	if { [lsearch $input_cookie $dbelt] == -1 } {
	    set new_cookie_necessary_p 1
	    set new_cookie [curriculum_progress_cookie_value $new_cookie $dbelt]
	}
    }
    foreach cookie_elt $input_cookie {
	if { [lsearch $elts_from_database $cookie_elt] == -1 && ![regexp {[A-z]} $cookie_elt] } {
	    # cookie contains no alphabet chars
	    set dupe_free_insert_sql "insert into user_curriculum_map (user_id, curriculum_element_id, completion_date)
select :user_id, :cookie_elt, sysdate
from dual
where not exists (select 1 from user_curriculum_map 
                  where user_id = :user_id
                  and curriculum_element_id = :cookie_elt)"
            if [catch { db_dml dupe_free_insert $dupe_free_insert_sql } errmsg] {
		# we got an error, probably because there is garbage in the user's
		# cookie and/or the publisher has deleted one of the curriculum elements
		ns_log Notice "curriculum_sync got an error from the database.  The user's cookie coming in was \"$cookie\".  Here's what the RDBMS had to say:\n\n$errmsg"
	    }
	}
    }
    if { $new_cookie_necessary_p && ($new_cookie != $input_cookie) } {
	return $new_cookie
    } else {
	return ""
    }
}

# this will be called before *.html and *.tcl pages, in general
proc curriculum_filter {conn args why} {
    # we don't want an error in the script to interrupt page service
    if [catch { curriculum_filter_internal $args $why } errmsg] {
	ns_log Error "curriculum_filter_internal coughed up $errmsg"
    }
    return "filter_ok"
}

proc curriculum_filter_internal {args why} {
    set cookie [ns_set get [ns_conn headers] Cookie]
    if { [regexp {CurriculumProgress=([^;]+)} $cookie {} input_cookie] } {
	# we have a cookie
	if { [string compare $input_cookie "finished"] == 0 } {
	    # user has completed curriculum, don't bother doing anything else
	} else {
	    # see what the user is looking at right now and compare
	    # to curriculum to consider adding to cookie
	    set the_big_list [util_memoize "curriculum_bar_all_db_rows"]
	    set table_elements [list]
	    foreach sublist $the_big_list {
		set curriculum_element_id [lindex $sublist 0]
		set url [lindex $sublist 1]
		if { [ns_conn url] == $url } {
		    # see if this element isn't already in user's cookie
		    if { [lsearch $input_cookie $curriculum_element_id] == -1 } {
			set new_cookie_value [curriculum_progress_cookie_value $input_cookie $curriculum_element_id]
			ns_set put [ns_conn outputheaders] "Set-Cookie" "CurriculumProgress=$new_cookie_value; path=/; expires=Fri, 01-Jan-2010 01:00:00 GMT"
			# if the user is logged in, we'll also want to record
			# the additional element in the database
			set user_id [ad_get_user_id]
			if { $user_id != 0 } {
			    # insert but only if there isn't a row already there
			    db_dml insert_user_curr_map "insert into user_curriculum_map (user_id, curriculum_element_id, completion_date)
select :user_id, :curriculum_element_id, sysdate
from dual
where not exists (select 1 from user_curriculum_map 
                  where user_id = :user_id
                  and curriculum_element_id = :curriculum_element_id)"
			}
		    }
		}
	    }
	}
    } else {
	# no cookie
	ns_set put [ns_conn outputheaders] "Set-Cookie" "CurriculumProgress=[curriculum_progress_cookie_value]; path=/; expires=Fri, 01-Jan-2010 01:00:00 GMT"
    }
}

ns_share -init {set curriculum_filters_installed_p 0} curriculum_filters_installed_p
if { [ad_parameter EnabledP curriculum 0] && !$curriculum_filters_installed_p} {
    set curriculum_filters_installed_p 1
    foreach filter_pattern [ad_parameter_all_values_as_list FilterPattern curriculum] {
	ns_log Notice "Installing curriculum filter for $filter_pattern"
	ad_register_filter postauth GET $filter_pattern curriculum_filter
    }
}

##################################################################
#
# interface to the ad-user-contributions-summary.tcl system

ns_share ad_user_contributions_summary_proc_list

if { [ad_parameter EnabledP curriculum 0] && ![info exists ad_user_contributions_summary_proc_list] || [util_search_list_of_lists $ad_user_contributions_summary_proc_list "Curriculum Progress" 0] == -1 } {
    lappend ad_user_contributions_summary_proc_list [list "Curriculum Progress" curriculum_user_contributions 0]
}

ad_proc curriculum_user_contributions {user_id purpose} {Returns list items, one for each curriculum posting} {
    if { $purpose != "site_admin" } {
	# we don't show user tracking data to other users!
	return [list]
    } 
    # we have to figure out whether this person is 
    #  (a) finished
    #  (b) hasn't started, or
    #  (c) in between
    # this query will pull the curriculum out in order that the 
    # user viewed the stuff, with the unviewed rows at the end
    set query "select url, one_line_description, completion_date
               from curriculum, (select curriculum_element_id, completion_date 
                    from user_curriculum_map
                    where user_id = :user_id) ucm
               where curriculum.curriculum_element_id = ucm.curriculum_element_id(+)
               order by completion_date asc"
    set found_uncompleted_element_p 0
    set found_completed_element_p 0
    
    db_foreach $query {
	if ![empty_string_p $completion_date] {
	    set found_completed_element_p 1
	    append items "<li>[util_AnsiDatetoPrettyDate $completion_date]: <a href=\"$url\">$one_line_description</a>\n"
	} else {
	    set found_uncompleted_element_p 1	    
	    append items "<li>not completed: <a href=\"$url\">$one_line_description</a>\n"
	}
    }
    
    if [empty_string_p $items] {
	return [list]
    } elseif { !$found_uncompleted_element_p && $found_completed_element_p } {
	# we have done them all
	return [list 0 "Curriculum Progress" "<ul><li>completed curriculum</ul>"]
    } elseif { $found_uncompleted_element_p && !$found_completed_element_p } {
	# we haven't done any!
	return [list 0 "Curriculum Progress" "<ul><li>hasn't started curriculum</ul>"]
    } else {
	return [list 0 "Curriculum Progress" "<ul>\n\n$items\n\n</ul>"]
    }
}


