# $Id: ad-user-contributions-summary.tcl,v 3.1 2000/02/20 17:04:39 davis Exp $
# 
# ad-user-contributions-summary.tcl
#
# by philg@mit.edu on October 31, 1999
#  (spending Halloween holiday engaged in the typically
#   ghoulish activity of Tcl programming)
#

# this is similar in spirit to what you see in ad-new-stuff.tcl

# the big idea here is to have a modular way of each part of ACS
# reporting what User #47 has contributed to the community
# This is used by /admin/users/one.tcl and /shared/community-member.tcl

# this system scales as modules are added to the ACS either by
# ArsDigita or publishers.  The basic mechanism by which modules buy
# into this system is to lappend a data structure to the ns_share
# variable ad_user_contributions_summary_proc_list (a Tcl list)

# each element of this list is itself a list.  Here's the data
# structure for the sublist:
#   module_name proc_name priority 
# a priority of 0 is higher than a priority of 1 (expect
# values between 0 and 10); items of the same priority 
# sort by which is shorter

util_report_library_entry

# assumes we're sorting a list of sublists, each of which 
# has priority as its first element, a title as the second, 
# and content as the third element 

proc ad_user_contributions_summary_sort {sublist1 sublist2} {
    set priority1 [lindex $sublist1 0]
    set priority2 [lindex $sublist2 0]
    if { $priority1 < $priority2 } {
	return -1 
    } elseif { $priority1 > $priority2 } {
	return 1
    } else {
	# priorities are equal, let's sort by length
	set string1 [lindex $sublist1 2]
	set string2 [lindex $sublist2 2]
	if { [string length $string1] < [string length $string2] } {
	    return -1
	} else {
	    return 1
	}
    }
}

proc_doc ad_summarize_user_contributions {db user_id {purpose "web_display"}} "Returns a string of a user's contributed stuff on the site.  The PURPOSE argument can be \"web_display\" (intended for an ordinary user) or \"site_admin\" (to help the owner of a site nuke stuff).  These arguments are passed down to the procedures on the ns_share'd ad_user_contributions_summary_proc_list." {
    ns_share ad_user_contributions_summary_proc_list
    set result_list [list]
    foreach sublist $ad_user_contributions_summary_proc_list {
	set module_name [lindex $sublist 0]
	set module_proc [lindex $sublist 1]
	# affects how we display the stuff
	set priority [lindex $sublist 2]

        # Put here so I get a traceback when subquery not released JCD
        #ns_log Notice "contibutions for $module_name via $module_proc"
        #set dbx [ns_db gethandle subquery] 
        #ns_db releasehandle $dbx

	if [catch { set one_module_result [eval [list $module_proc $db $user_id $purpose]] } errmsg] {
	    ns_log Notice "ad_summarize_user_contributions got an error calling $module_proc:  $errmsg"
	    # got an error, let's continue to the next iteration
	    continue
	}
	if { [llength $one_module_result] != 0 && ![empty_string_p [lindex $one_module_result 2]] } {
	    # we got back a triplet AND there was some actual content
	    lappend result_list $one_module_result
	}
    }
    # we've got all the results, let's sort by priority and then size
    set sorted_list [lsort -command ad_user_contributions_summary_sort $result_list]
    set html_fragment ""
    foreach result_elt $sorted_list {
	set subsection_title [lindex $result_elt 1]
	set subsection_contents [lindex $result_elt 2]
	append html_fragment "<h3>$subsection_title</h3>\n\n$subsection_contents\n\n"
    }
    return $html_fragment
}

# now let's define new stuff procs for all the random parts of the
# system that don't have their own defs files or aren't properly 
# considered modules 

ns_share ad_user_contributions_summary_proc_list

if { ![info exists ad_user_contributions_summary_proc_list] || [util_search_list_of_lists $ad_user_contributions_summary_proc_list "Related Links" 0] == -1 } {
    lappend ad_user_contributions_summary_proc_list [list "Related Links" ad_related_links_user_contributions 1]
}


proc_doc ad_related_links_user_contributions {db user_id purpose} "Only produces a report for the site administrator; the assumption is that random users won't want to see out-of-context links" {
    if { $purpose != "site_admin" } {
	return [list]
    }
    set selection [ns_db select $db "select links.page_id, links.link_title, links.link_description, links.url, links.status, posting_time, page_title, url_stub
from links, static_pages sp
where links.page_id = sp.page_id
and links.user_id = $user_id
order by posting_time asc"]
    set items ""
    while { [ns_db getrow $db $selection] } {
	set_variables_after_query
	append items "<li>[util_AnsiDatetoPrettyDate $posting_time] 
to 
<a href=\"$url_stub\">$url_stub</a>: 
<ul>
<li>Url:  <a href=\"$url\">$url</a> ($link_title)
"
        if ![empty_string_p $link_description] {
	    append items "<li>Description:  $link_description\n"
	}
	append items "<li>Status:  $status
<li>Actions: &nbsp; &nbsp; <a href=\"/admin/links/edit.tcl?[export_url_vars url page_id]\">edit</a> &nbsp; &nbsp;  <a href=\"/admin/links/delete.tcl?[export_url_vars url page_id]\">delete</a>
</ul>
"
    }
    if [empty_string_p $items] {
	return [list]
    } else {
	return [list 1 "Related Links" "<ul>\n\n$items\n\n</ul>"]
    }
}

if { ![info exists ad_user_contributions_summary_proc_list] || [util_search_list_of_lists $ad_user_contributions_summary_proc_list "Static Page Comments" 0] == -1 } {
    lappend ad_user_contributions_summary_proc_list [list "Static Page Comments" ad_static_comments_user_contributions 1]
}


proc_doc ad_static_comments_user_contributions {db user_id purpose} "Returns a list of priority, title, and an unordered list HTML fragment.  All the static comments posted by a user." {
    if { $purpose == "site_admin" } {
	return [ad_static_comments_user_contributions_for_site_admin $db $user_id]
    } else {
	return [ad_static_comments_user_contributions_for_web_display $db $user_id]	
    }
	
}


# need to go the helper route 
proc ad_static_comments_user_contributions_for_site_admin {db user_id} {
    set selection [ns_db select $db "select comments.comment_id, comments.page_id, comments.message, comments.posting_time, comments.comment_type, comments.rating, page_title, url_stub
from static_pages sp, comments_not_deleted comments
where comments.page_id = sp.page_id
and comments.user_id = $user_id
order by posting_time asc"]
    set items ""
    while { [ns_db getrow $db $selection] } {
	set_variables_after_query
	append items "<li>[util_AnsiDatetoPrettyDate $posting_time]; $comment_type on <a href=\"$url_stub\">$url_stub</a>:
	<blockquote>
	"
	if ![empty_string_p $rating] {
	    append items "Rating:  $rating<br><br>\n\n"
	}    
	append items "
$message
<br>
<br>
\[ <a href=\"/admin/comments/persistent-edit.tcl?[export_url_vars comment_id]\">edit</a> &nbsp; | &nbsp; <a href=\"/admin/comments/delete.tcl?[export_url_vars comment_id page_id]\">delete</a> \]
</blockquote>"
    }
    if [empty_string_p $items] {
	return [list]
    } else {
	return [list 1 "Static Page Comments" "<ul>\n\n$items\n\n</ul>"]
    }
}

proc ad_static_comments_user_contributions_for_web_display {db user_id} {
    set selection [ns_db select $db "select comments.page_id, comments.message, posting_time, decode(page_title, null, url_stub, page_title) page_title, url_stub 
from static_pages sp, comments_not_deleted comments
where sp.page_id = comments.page_id
and comments.user_id = $user_id
and comments.comment_type = 'alternative_perspective'
order by posting_time asc"]
    set comment_items ""
    while { [ns_db getrow $db $selection] } {
	set_variables_after_query
	if { [string length $message] > 1000 } {
	    set complete_message "[string range $message 0 1000]... "
	} else {
	    set complete_message $message
	}
	append comment_items "<li>[util_AnsiDatetoPrettyDate $posting_time], on <a href=\"$url_stub\">$page_title</a>: 
<blockquote>
$complete_message
</blockquote>
<p>
"
    }
    if [empty_string_p $comment_items] {
	return [list]
    } else {
	return [list 1 "Static Page Comments" "<ul>\n\n$comment_items\n\n</ul>"]
    }
}


util_report_successful_library_load
