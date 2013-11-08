# /tcl/news-defs.tcl

ad_library {
    functions for the /news module, including its
    interface with ad-new-stuff.tcl 

    @author philg@mit.edu
    @creation-date 07/04/99
    @cvs-id news-defs.tcl,v 3.8.2.4 2000/09/22 01:34:03 kevin Exp
}


proc_doc news_newsgroup_id_list { user_id group_id } { Returns the list of newsgroup_ids for the
appropriate news items for this user and group. If the user_id exists (i.e. non zero) then the list includes the registered_users. If group_id is set, then the newsgroup for the group is added (if it exists). } {

    # Build the newsgroup clause
    set scope_clause_list [list "scope = 'all_users'"]

    if { $user_id != 0 } {
	lappend scope_clause_list "scope = 'registered_users'"
    }

    if { $group_id > 0 } {
	lappend scope_clause_list "(scope = 'group' and group_id = :group_id)"
    } else {
	lappend scope_clause_list "scope = 'public'"
    }

    return [db_list newsgroup_ids_by_scope \
	    "select newsgroup_id from newsgroups where [join $scope_clause_list " or "]"]
}

ns_share ad_new_stuff_module_list

if { ![info exists ad_new_stuff_module_list] || [lsearch -glob $ad_new_stuff_module_list "News*"] == -1 } {
    lappend ad_new_stuff_module_list [list "News" news_new_stuff]
}

# added two additional arguments and a parameter to this proc
#  - include_comments_p - if set to 0, we skip the comments regardless of the type. This
#    is good for adding news to user workspaces
#  - DefaultNumberOfStoriesToDisplay .ini Parameter: Specified the maximum number of stories
#    to display. An active site can have a lot of news in a month! Use this parameter to
#    say "Only display the 10 most recent news items"
#  - include_date_p: Prepends the news item with it's release date
# brucek: added group_id argument to filter group-specific news
#         how_many to override the ini parameter

proc news_new_stuff {since_when only_from_new_users_p purpose { include_date_p 0 } { include_comments_p 1 } { group_id 0 } { how_many 0 }} {

    # Get the user_id for finding which newsgroups this user can see.
    set user_id [ad_get_user_id]

    if { $only_from_new_users_p == "t" } {
	set users_table "users_new"
    } else {
	set users_table "users"
    }
    # What is the maximum number of rows to return?
    # the how_many proc argument has precedence over the value in the ini file
    if { $how_many > 0 } {
	set max_stories_to_display $how_many
    } else {
	set max_stories_to_display [ad_parameter DefaultNumberOfStoriesToDisplay news -1]
    }

    # Create a clause for returning the postings for relavent groups
    # Don't have to bind this here because news_newsgroup_id_list binds group_id, if used,
    #  so that all the values in this clause are already from the database
    set newsgroup_clause "(newsgroup_id = [join [news_newsgroup_id_list $user_id $group_id] " or newsgroup_id = "])"
    

    if { $purpose == "site_admin" } {
	set query "select news.title, news.news_item_id, news.approval_state, 
 expired_p(news.expiration_date) as expired_p, 
 to_char(news.release_date,'Mon DD, YYYY') as release_date_pretty
from news_items news, $users_table ut
where creation_date > :since_when
and $newsgroup_clause
and news.creation_user = ut.user_id
order by creation_date desc"
    } else {
	# only showed the approved and released stuff
	set query "select news.title, news.news_item_id, news.approval_state, 
 expired_p(news.expiration_date) as expired_p, 
 to_char(news.release_date,'Mon DD, YYYY') as release_date_pretty
from news_items news, $users_table ut
where creation_date > :since_when
and $newsgroup_clause
and news.approval_state = 'approved'
and release_date < sysdate
and news.creation_user = ut.user_id
order by release_date desc, creation_date desc"
    }
    set result_items ""
    set counter 0
    db_foreach news_info $query {
	switch $purpose {
	    web_display {
		append result_items "<li>[util_decode $include_date_p 1 "$release_date_pretty: " ""]<a href=\"/news/item?news_item_id=$news_item_id\">$title</a>\n" }
	    site_admin { 
		append result_items "<li>[util_decode $include_date_p 1 "$release_date_pretty: " ""]<a href=\"/admin/news/item?news_item_id=$news_item_id\">$title</a>"
		if { ![string match $approval_state "approved"] } {
		    append result_items "&nbsp; <font color=red>not approved</font>"
		}
		append result_items "\n"
	    }
	    email_summary {
		append result_items "[util_decode $include_date_p 1 "$release_date_pretty: " ""]$title
  -- [ad_url]/news/item.tcl?news_item_id=$news_item_id
"
            }
	}
	incr counter
	if { $max_stories_to_display > 0 && $counter >= $max_stories_to_display } {
	    break
	}
    }
    if { ! $include_comments_p } {
	return $result_items
    } 
    # we have the result_items or not
    if { $purpose == "email_summary" } {
	set tentative_result $result_items
    } elseif { ![empty_string_p $result_items] } {
	set tentative_result $result_items
    } else {
	set tentative_result ""
    }
    # now let's move into the comments on news territory (we don't do
    # this in a separate new-stuff proc because we want to keep it 
    # together with the new news)
    if { $purpose == "email_summary" } {
	# the email followers aren't going to be interested in comments
	return $tentative_result
    }
    if { $purpose == "site_admin" } {
	set where_clause_for_approval ""
    } else {
	set where_clause_for_approval "and gc.approved_p = 't'"
    }
    set comment_query "
select 
  gc.comment_id, 
  gc.on_which_table, 
  gc.html_p as comment_html_p,
  dbms_lob.substr(gc.content,100,1) as content_intro, 
  gc.on_what_id,
  users.user_id as comment_user_id, 
  gc.comment_date,
  first_names || ' ' || last_name as commenter_name, 
  gc.approved_p,
  news.title, 
  news.news_item_id 
from general_comments gc, $users_table users, news_items news
where users.user_id = gc.user_id 
and gc.on_which_table = 'news_items'
and gc.on_what_id = news.news_item_id
$where_clause_for_approval
and comment_date > :since_when
order by gc.comment_date desc"

    set result_items ""
    db_foreach news_comment_query $comment_query {
	if { $comment_html_p == "t" } {
	    regsub {<[^>]*$} $content_intro "" content_intro
	}

	switch $purpose {
	    web_display {
		append result_items "<li>comment from <a href=\"/shared/community-member?user_id=$comment_user_id\">$commenter_name</a> on <a href=\"/news/item?news_item_id=$news_item_id\">$title</a>:
<blockquote>
$content_intro ...
</blockquote>
"
            }
	    site_admin { 
		append result_items "<li>comment from <a href=\"/admin/users/one?user_id=$comment_user_id\">$commenter_name</a> on <a href=\"/admin/news/item?news_item_id=$news_item_id\">$title</a>:
<blockquote>
$content_intro ...
</blockquote>
"
	    }
	}
    }
    if ![empty_string_p $result_items] {
	append tentative_result "\n<h4>comments on news items</h4>\n\n$result_items"
    }
    if ![empty_string_p $tentative_result] {
	return "<ul>\n\n$tentative_result\n</ul>"
    } else {
	return ""
    }
}

##################################################################
#
# interface to the ad-user-contributions-summary.tcl system

ns_share ad_user_contributions_summary_proc_list

if { ![info exists ad_user_contributions_summary_proc_list] || [util_search_list_of_lists $ad_user_contributions_summary_proc_list "/news postings" 0] == -1 } {
    if { [ad_parameter EnabledP user-contributions 0] == 1 } {
        lappend ad_user_contributions_summary_proc_list [list "/news postings" news_user_contributions 0]
    }
}

proc_doc news_user_contributions {user_id purpose} {Returns list items, one for each news posting} {


    if { $purpose == "site_admin" } {
	set restriction_clause ""
    } else {
	set restriction_clause "\nand n.approval_state = 'approved'"
    }

    set sql "
    select n.news_item_id, n.title, n.approval_state, n.release_date, ng.scope, 
           ng.group_id, ug.group_name, ug.short_name,
           decode(ng.scope, 'all_users', 1, 'registered_users', 1, 'public', 1, 'group', 4, 5)
             as scope_ordering
    from news_items n, newsgroups ng, user_groups ug 
    where n.creation_user = :user_id $restriction_clause
    and n.newsgroup_id = ng.newsgroup_id
    and ng.group_id=ug.group_id(+)
    order by scope_ordering, ng.group_id, n.release_date"

    set items ""
    set last_group_id ""
    set item_counter 0
    db_foreach user_contributions $sql {

	switch $scope {
	    public {
		if { $item_counter==0 } {
		    append items "<h4>Public News Postings</h4>"		    
		    set root_url "/news"
		    set admin_root_url "/news/admin"
		}
	    }
	    group {
		if { $last_group_id!=$group_id } {
		    append items "<h4>$group_name News Postings</h4>"
		    
		    if { [db_0or1row section_key_from_group_id "
		    select section_key
		    from content_sections
		    where scope='group' and group_id=:group_id
		    and module_key='news'"] } {

			set root_url "[ug_url]/[ad_urlencode $short_name]/[ad_urlencode $section_key]"
			set admin_root_url "[ug_admin_url]/[ad_urlencode $short_name]/[ad_urlencode $section_key]"
		    } else {
			set root_url "/news"
			set admin_root_url "/news/admin"
		    }
		}
	    } 
	}

	if { $purpose == "site_admin" } {
	    append items "<li>[util_AnsiDatetoPrettyDate $release_date]: <a href=\"$admin_root_url/item?[export_url_vars news_item_id]\">$title</a>\n"
	    if { ![string match $approval_state "approved"] } {
		append items "&nbsp; <font color=red>not approved</font>"
	    }
	} else {
	    append items "<li>[util_AnsiDatetoPrettyDate $release_date]: <a href=\"$root_url/item?[export_url_vars news_item_id]\">$title</a>\n"
	}
	set last_group_id $group_id
	incr item_counter
    }

    if [empty_string_p $items] {
	return [list]
    } else {
	return [list 0 "News Postings" "<ul>\n\n$items\n\n</ul>"]
    }

}

proc_doc news_admin_authorize { news_item_id } "given news_item_id, this procedure will check whether the user can administer this news item (e.g. for scope=group, this proc will check whether the user is group administrator). if news doesn't exist page is served to the user informing him that the news item doesn't exist. if successfull it will return user_id of the administrator." {
    
    set sql "
    select news_item_id, scope, group_id
    from news_items, newsgroups
    where news_item_id=:news_item_id
    and news_items.newsgroup_id = newsgroups.newsgroup_id"

    if { ![db_0or1row news_info $sql] } {
	# news item doesn't exist
	uplevel {
	    doc_return  200 text/html "
	    [ad_scope_admin_header "News Item Does not Exist"]
	    [ad_scope_admin_page_title "News Item Does not Exist"]
	    [ad_scope_admin_context_bar [list index?[export_url_scope_vars]  "News Admin"] "No News Item"]
	    <hr>
	    <blockquote>
	    Requested News Item does not exist.
	    </blockquote>
	    [ad_scope_admin_footer]
	    "
	}
	ad_script_abort
    }
 
    set id 0
    switch $scope {
	public {
	    set id 0
	}
	group {
	    set id $group_id
	}
    }

    set authorization_status [ad_scope_authorization_status $scope admin group_admin none $id]

    set user_id [ad_verify_and_get_user_id]

    switch $authorization_status {
	authorized {
	    return $user_id
	}
	not_authorized {
	    ad_return_warning "Not authorized" "You are not authorized to see this page"
	    ad_script_abort
	}
	reg_required {
	    ad_redirect_for_registration
	    ad_script_abort
	}
    }
}

proc_doc news_item_comments { news_item_id } "Displays the comments for this newsgroups items with a link to toggle the approval status." {
    

    set return_string ""

    set sql "
    select comment_id, content, comment_date, 
    first_names || ' ' || last_name as commenter_name, 
    users.user_id as comment_user_id, html_p as comment_html_p, 
    general_comments.approved_p as comment_approved_p 
    from general_comments, users
    where on_what_id= :news_item_id 
    and on_which_table = 'news_items'
    and general_comments.user_id = users.user_id"
    
    db_foreach news_item_comments $sql {

	append return_string "<a href=\"/shared/community-member?user_id=$comment_user_id\">$commenter_name</a>"

	# print out the approval status if we are using the approval system
	if { [ad_parameter CommentApprovalPolicy news] != "open"} {
	    if {$comment_approved_p == "t" } {
		append return_string " -- <a href=\"comment-toggle-approval?[export_url_vars comment_id news_item_id]\">Revoke approval</a>"
	    } else {
		append return_string " -- <a href=\"comment-toggle-approval?[export_url_vars comment_id news_item_id]\">Approve</a>"
	    }
	}

	append return_string "<blockquote>\n[util_maybe_convert_to_html $content $comment_html_p]</blockquote>"

    }

    if { [empty_string_p $return_string] } {
	return ""
    } else {
	return "<h4>Comments</h4>\n<ul>$return_string</ul>\n"
    }
}
