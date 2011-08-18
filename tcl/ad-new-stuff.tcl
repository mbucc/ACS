# $Id: ad-new-stuff.tcl,v 3.0.4.1 2000/04/11 16:19:39 carsten Exp $
# 
# ad-new-stuff.tcl
#
# by philg@mit.edu on July 4, 1999
#  (spending the holiday engaged in the typical American
#   Revolutionary activity of Tcl programming, which drove
#   out the effete British computer scientists)
#

# the big idea here is to have a central facility to look at content
# posted by users across the entire site.  This is useful for the site
# administrator (might want to delete stuff).  This is useful for the 
# surfing user (might want to click through to stuff).  This is useful
# for generating email summaries.

# one weird extra feature is that we have an argument to limit to new 
# content posted by new users.  This is an aid to moderators.  Basically
# the idea is that new content posted by a person who has been a community
# member for a year is unlikely to require deletion.  But new content
# posted by a brand new community member is very likely to require scrutiny
# since the new user may not have picked up on the rules and customs
# of the community.

# (publishers who require approval before content goes live will want
# to see old users' contributions highlighted as well since these need
# to be approved quickly)

# this system scales as modules are added to the ACS either by
# ArsDigita or publishers.  The basic mechanism by which modules buy
# into this system is to lappend a data structure to the ns_share
# variable ad_new_stuff_module_list (a Tcl list)

# each element of this list is itself a list.  Here's the data
# structure for the sublist:
#   module_name proc_name 

util_report_library_entry

proc ad_new_stuff_sort_by_length {string1 string2} {
    if { [string length $string1] < [string length $string2] } {
	return -1
    } else {
	return 1
    }
}

proc_doc ad_new_stuff {db {since_when ""} {only_from_new_users_p "f"} {purpose "web_display"}} "Returns a string of new stuff on the site.  SINCE_WHEN is an ANSI date.  If ONLY_FROM_NEW_USERS_P is \"t\" then we only look at content posted by users in the USERS_NEW view.  The PURPOSE argument can be \"web_display\" (intended for an ordinary user), \"site_admin\" (to help the owner of a site nuke stuff), or \"email_summary\" (in which case we get plain text back).  These arguments are passed down to the procedures on the ns_share'd ad_new_stuff_module_list." {
    # let's default the date if we didn't get one
    if [empty_string_p $since_when] {
	set since_when [database_to_tcl_string $db "select sysdate-1 from dual"]
    }
    ns_share ad_new_stuff_module_list
    set result_list [list]
    foreach sublist $ad_new_stuff_module_list {
	set module_name [lindex $sublist 0]
	set module_proc [lindex $sublist 1]
	set result_elt ""
	if [catch { set subresult [eval "$module_proc $db $since_when $only_from_new_users_p $purpose"] } errmsg ] {
	    # got an error, let's continue to the next iteration
	    ns_log Warning "$module_proc, called from ad_new_stuff, returned an error:\n$errmsg"
	    continue
	}
	if ![empty_string_p $subresult] {
	    # we got something, let's write a headline 
	    if { $purpose == "email_summary" } {
		append result_elt "[string toupper $module_name]\n\n"
	    } else {
		append result_elt "<h3>$module_name</h3>\n\n"
	    }
	    append result_elt "$subresult"
	    append result_elt "\n\n"
	    lappend result_list $result_elt
	}
    }
    # we've got all the results, let's sort by size
    set sorted_list [lsort -command ad_new_stuff_sort_by_length $result_list]
    return [join $sorted_list ""]
}

# now let's define new stuff procs for all the random parts of the
# system that don't have their own defs files or aren't properly 
# considered modules 

ns_share ad_new_stuff_module_list

if { ![info exists ad_new_stuff_module_list] || [util_search_list_of_lists $ad_new_stuff_module_list "Related Links" 0] == -1 } {
    lappend ad_new_stuff_module_list [list "Related Links" ad_related_links_new_stuff]
}


proc_doc ad_related_links_new_stuff {db since_when only_from_new_users_p purpose} "Only produces a report for the site administrator; the assumption is that random users won't want to see out-of-context links" {
    if { $purpose != "site_admin" } {
	return ""
    }
    if { $only_from_new_users_p == "t" } {
	set users_table "users_new"
    } else {
	set users_table "users"
    }
    set query "select links.link_title, links.link_description, links.url, links.status,  posting_time,
ut.user_id, first_names || ' ' || last_name as name, links.url, sp.page_id, sp.page_title, sp.url_stub
from static_pages sp, links, $users_table ut
where sp.page_id (+) = links.page_id
and ut.user_id = links.user_id
and posting_time > '$since_when'
order by posting_time desc"
    set result_items ""
    set selection [ns_db select $db $query]
    while { [ns_db getrow $db $selection] } {
	set_variables_after_query
	append result_items "<li>[util_AnsiDatetoPrettyDate $posting_time]: 
<a href=\"$url\">$link_title</a> "
        if { $status != "live" } {
	    append result_items "(<font color=red>$status</font>)"
	}
	append result_items "- $link_description 
<br>
--
posted by <a href=\"/admin/users/one.tcl?user_id=$user_id\">$name</a> 
on  <a href=\"/admin/static/page-summary.tcl?page_id=$page_id\">$url_stub</a>   
&nbsp; 
\[
<a target=working href=\"/admin/links/edit.tcl?[export_url_vars url page_id]\">edit</a> |
<a target=working href=\"/admin/links/delete.tcl?[export_url_vars url page_id]\">delete</a> |
<a target=working href=\"/admin/links/blacklist.tcl?[export_url_vars url page_id]\">blacklist</a>
\]
<p>
"
    }
    if { ![empty_string_p $result_items] } {
	return "<ul>\n\n$result_items\n</ul>\n"
    } else {
	return ""
    }
}

ns_share ad_new_stuff_module_list

if { ![info exists ad_new_stuff_module_list] || [util_search_list_of_lists $ad_new_stuff_module_list "Comments on Static Pages" 0] == -1 } {
    lappend ad_new_stuff_module_list [list "Comments on Static Pages" ad_comments_on_static_new_stuff]
}


proc_doc ad_comments_on_static_new_stuff {db since_when only_from_new_users_p purpose} "Produces a report for the site administrator and also a compressed version for random surfers and email summary recipients" {
    if { $only_from_new_users_p == "t" } {
	set users_table "users_new"
    } else {
	set users_table "users"
    }
    set n_bytes_to_show 750
    set query "select comments.comment_id, dbms_lob.getlength(comments.message) as n_message_bytes, dbms_lob.substr(comments.message,$n_bytes_to_show,1) as message_intro, comments.rating, comments.comment_type, posting_time, comments.originating_ip, users.user_id, first_names || ' ' || last_name as name, comments.page_id, sp.url_stub, sp.page_title, nvl(sp.page_title,sp.url_stub) as page_title_anchor, client_file_name, html_p, file_type, original_width, original_height, caption
from static_pages sp, comments_not_deleted comments, $users_table users
where sp.page_id = comments.page_id
and users.user_id = comments.user_id
and posting_time > '$since_when'
order by comment_type, posting_time desc"
    set result_items ""
    set last_comment_type ""
    set selection [ns_db select $db $query]
    while { [ns_db getrow $db $selection] } {
	set_variables_after_query
	if { $n_message_bytes > $n_bytes_to_show } {
	    set ellipses " ..."
	} else {
	    set ellipses ""
	}
	# truncation within Oracle might have left open HTML tags; let's close them
	set message_intro_cleaned "[util_close_html_tags $message_intro]$ellipses"
	switch $purpose {
	    web_display {
		if { $comment_type == "alternative_perspective" } {
		    append result_items "<li>by <a href=\"/shared/community-member.tcl?[export_url_vars user_id]\">$name</a>
on <a href=\"$url_stub\">$page_title_anchor</a>:
<blockquote>
[format_static_comment $comment_id $client_file_name $file_type $original_width $original_height $caption $message_intro_cleaned $html_p]
</blockquote>
"
                }
	    }
	    site_admin { 
		if { $comment_type != $last_comment_type } {
		    append result_items "<h4>$comment_type</h4>\n"
		    set last_comment_type $comment_type
		}
		append result_items "<li>[util_AnsiDatetoPrettyDate $posting_time]: "
		if { ![empty_string_p $rating] } {
		    append result_items "$rating -- "
		}
		append result_items "[format_static_comment $comment_id $client_file_name $file_type $original_width $original_height $caption $message_intro_cleaned $html_p]
<br>
-- <a href=\"/admin/users/one.tcl?user_id=$user_id\">$name</a> 
from $originating_ip
on <a href=\"/admin/static/page-summary.tcl?[export_url_vars page_id]\">$url_stub</a>"
                if ![empty_string_p $page_title] {
		    append result_items " ($page_title) "
		}
		append result_items "&nbsp; &nbsp; <a href=\"/admin/comments/persistent-edit.tcl?[export_url_vars comment_id]\" target=working>edit</a> &nbsp; &nbsp;  <a href=\"/admin/comments/delete.tcl?[export_url_vars comment_id page_id]\" target=working>delete</a>
<p>
"
	    }
	    email_summary {
		if { $comment_type == "alternative_perspective" } {
		    # make sure to have space after URL so mail REGEXPs will offer users hyperlinks
		    append result_items "by $name on [ad_url]$url_stub :
[wrap_string [ns_striphtml $message_intro]]$ellipses

-----
"
                }
            }
	}
    }
    # we have the result_items or not
    if { $purpose == "email_summary" } {
	return $result_items
    } elseif { ![empty_string_p $result_items] } {
	return "<ul>\n\n$result_items\n</ul>\n"
    } else {
	return ""
    }
    
}

ns_share ad_new_stuff_module_list

if { ![info exists ad_new_stuff_module_list] || [util_search_list_of_lists $ad_new_stuff_module_list "Users" 0] == -1 } {
    lappend ad_new_stuff_module_list [list "Users" ad_users_new_stuff]
}


proc_doc ad_users_new_stuff {db since_when only_from_new_users_p purpose} "Produces a report for the site administrator; nothing for random surfers and email summary recipients" {
    if { $purpose != "site_admin" } {
	return ""
    }
    set n_new [database_to_tcl_string $db "select count(*) from users where registration_date > '$since_when'"]
    if { $n_new == 0 } {
	return ""
    } elseif { $n_new < 10 } {
	# let's display the new users in-line
	set result_items ""
	set selection [ns_db select $db "select user_id, first_names, last_name, email from users where registration_date > '$since_when'"]
	while { [ns_db getrow $db $selection] } {
	    set_variables_after_query
	    append result_items "<li><a href=\"/admin/users/one.tcl?[export_url_vars user_id]\">$first_names $last_name</a> ($email)\n"
	}
	return "<ul>\n\n$result_items\n</ul>\n"
    } else {
	# lots of new users
	return "<ul>\n<li><a href=\"/admin/users/action-choose.tcl?registration_after_date=[ns_urlencode $since_when]\">$n_new new users</a>\n</ul>\n"
    }
}

util_report_successful_library_load

