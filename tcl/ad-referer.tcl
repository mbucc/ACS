# $Id: ad-referer.tcl,v 3.1 2000/02/26 12:55:27 jsalz Exp $
 # ad-referer.tcl

# we've misspelled "referrer" because it is misspelled in the HTTP
# standard

# created by philg@mit.edu on 7/4/98 and teadams@mit.edu
# modified by teadams@mit.edu on 2/7/98 to exclude local urls like .jpg and .gif
# modified by philg@mit.edu on November 24, 1999 to handle concurrency problem
# (on first insert of the day)

# checks to see if there is an external referer header
# then tries to get db conn
# then increments counter

util_report_library_entry

proc ad_referer_external_p {referer_header} {
    set local_hostnames [ad_parameter_all_values_as_list LocalDomain referer] 
    foreach hostname $local_hostnames {
	if { [string match [string tolower "*//$hostname*/*"] [string tolower $referer_header]]} {
	    # we found a match in between // and /; the match was done case-insensitive
	    # we also put in a wildcard in case the port number was included, e.g.,
	    # "photo.net:80" "photo.net:443"
	    return 0
	}
    }
    # didn't match any of the local hostnames
    return 1
}

proc ad_referer_include_p {referer_header} {
    set inclusion_globs [ad_parameter_all_values_as_list InclusionGLOB referer]
    if { [llength $inclusion_globs] == 0 } {
	# there aren't any required inclusion patterns, so assume this is OK
	return 1
    } else {
	foreach glob_pattern $inclusion_globs {
	    if {[string match $glob_pattern $referer_header]} {
		return 1
	    }
	}
	# nothing matched
	return 0
    }
}

proc ad_track_referer_p { } {
    if { [string match *.jpg [ns_conn url]] || [string match *.gif [ns_conn url]] } {
	# we don't want to track referers to this url
	return 0
    } else {
	return 1
    }
}

# on March 7, 1999 philg added the <= 250 characters clause because his 
# error log was getting spammed a bit with weird long referers from sites
# such as www.askjeeves.com

proc ad_referer_filter {conn args why} {
    set referer [ns_set get [ns_conn headers] Referer]
    if { ![empty_string_p $referer] && [ad_referer_external_p $referer] && [ad_referer_include_p $referer] && [ad_track_referer_p] && ([string length $referer] <= 250) } {
	# we have an external header, and the local url
	# we wish to track let's try to get a db conn
	if { [catch { set db [ns_db gethandle -timeout -1 log] } errmsg] || [empty_string_p $db] } {
	    # the non-blocking call to gethandle raised a Tcl error; this
	    # means a db conn isn't free right this moment, so let's just
	    # return
	    return filter_ok
	} else {
	    # we have $db
	    # let's try to figure out if we should log it straight 
	    # or reduced down with a GLOB pattern
	    set selection [ns_db select $db "select * from referer_log_glob_patterns"]
	    set globbed_p 0
	    set regexp_p 0
	    while { [ns_db getrow $db $selection] } {
		set_variables_after_query
		if [string match $glob_pattern $referer] {
		    # we don't want to log under the raw string
		    set globbed_p 1
		    if { $search_engine_name != "" && [regexp $search_engine_regexp $referer match query_string] } {			
			# this glob pattern is for a search engine AND 
			# we successfully REGEXP'd for the query string
			set user_id [ad_get_user_id]
			if { $user_id == 0 } {
			    set complete_user_id NULL
			} else {
			    set complete_user_id $user_id
			}
			set regexp_p 1
			break
		    } else {
			# we globbed but weren't a search engine 
			# or couldn't find the query-string, bust out of the loop
			break
		    }
		}
	    }

	    if $globbed_p {
		set foreign_url $canonical_foreign_url
	    } else {
		set foreign_url $referer
	    }
	    
	    # if we found a match the regular expression

	    if $regexp_p {
		ns_db dml $db "insert into query_strings (query_date, query_string, search_engine_name, user_id)
values
(sysdate,'[DoubleApos [ns_urldecode $query_string]]','[DoubleApos $search_engine_name]',$complete_user_id)"
            }

	    set update_sql "update referer_log set click_count = click_count + 1
where local_url = '[DoubleApos [ns_conn url]]' 
and foreign_url = '[DoubleApos $foreign_url]'
and trunc(entry_date) = trunc(sysdate)"
           ns_db dml $db $update_sql
           
           set n_rows [ns_ora resultrows $db]
           if { $n_rows == 0 } {
	       # there wasn't already a row there; we want to insert a new row
	       # but we have to be careful because we're not inside a database
	       # transaction.  It is possible another thread is simultaneously
	       # executing this logic and inserting an extra row.
	       set insert_sql "insert into referer_log (local_url, foreign_url, entry_date, click_count)
select '[DoubleApos [ns_conn url]]', '[DoubleApos $foreign_url]', trunc(sysdate), 1
from dual
where 0 = (select count(*) 
           from referer_log
           where local_url = '[DoubleApos [ns_conn url]]'
           and foreign_url = '[DoubleApos $foreign_url]'
           and trunc(entry_date) = trunc(sysdate))"
               ns_db dml $db $insert_sql
           }
	   ns_db releasehandle $db
       }
   }
    # regardless of what happened above, return OK
    return filter_ok
}

ns_share -init { set ad_referer_filters_installed_p 0 } ad_referer_filters_installed_p

if { !$ad_referer_filters_installed_p } {
	set ad_referer_filters_installed_p 1
	ad_register_filter trace GET * ad_referer_filter
}


##################################################################
#
# interface to the ad-user-contributions-summary.tcl system
#
# (to report user searches to the site administrator only)
#

ns_share ad_user_contributions_summary_proc_list

if { ![info exists ad_user_contributions_summary_proc_list] || [util_search_list_of_lists $ad_user_contributions_summary_proc_list "Searches" 0] == -1 } {
    lappend ad_user_contributions_summary_proc_list [list "Searches" searches_user_contributions 0]
}

proc_doc searches_user_contributions {db user_id purpose} {Returns empty list if purpose is not "site_admin".  Otherwise a triplet including all the searches typed on this site while this user was logged in or was referred in.} {
    if { $purpose != "site_admin" } {
	return [list]
    }
    set selection [ns_db select $db "select query_date, 
decode(subsection, null, search_engine_name, subsection) location, 
decode(n_results, null, '', ' - ' || n_results || ' result(s)') n_results_string, query_string
from query_strings
where user_id = $user_id
order by query_date asc
"]

    set items ""
    while {[ns_db getrow $db $selection]} {
	set_variables_after_query
	append items "<li>$query_date:</a>
<a href=\"/admin/searches/by-word.tcl?query_string=[ns_urlencode $query_string]\"><b>$query_string</b></a>
<a href=\"/admin/searches/by-location.tcl?location=[ns_urlencode $location]\">($location)</a>
$n_results_string
"
    }
    if [empty_string_p $items] {
	return [list]
    } else {
	return [list 0 "Searches" "<ul>\n\n$items\n\n</ul>"]
    }
}



util_report_successful_library_load
