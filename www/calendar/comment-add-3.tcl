# www/calendar/comment-add-3.tcl
ad_page_contract {
    Phase three - Insert
    of the three-step process to add a General Comment to a calendar item
    
    Number of queries: 1 or 2
    
    @author Philip Greenspun (philg@mit.edu)
    @author Sarah Ahmed (ahmeds@arsdigita.com)
    @creation-date 1998-11-18
    @cvs-id comment-add-3.tcl,v 3.3.2.7 2001/01/10 16:41:44 khy Exp
    @last-modified 2000-07-12
    @last-modified-by Michael Shurpik (mshurpik@arsdigita.com)
} {
    calendar_id:integer
    comment_id:notnull,integer,verify
    html_p:notnull
    content:allhtml
    {scope public}
    {user_id ""}
    {group_id ""}
    {on_what_id ""}
    {on_which_group ""}
}



## Original Comments:

# comment-add-3.tcl,v 3.3.2.7 2001/01/10 16:41:44 khy Exp
# File:     /calendar/comment-add-3.tcl
# Date:     1998-11-18
# Contact:  philg@mit.edu, ahmeds@arsdigita.com
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

## Original set_form comments:

# calendar_id, content, comment_id, content, html_p
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)


if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}


ad_scope_error_check

ad_scope_authorize $scope all group_member registered


# check for bad input
if { ![info exists content] || [empty_string_p $content] } {
    ad_scope_return_complaint 1 "<li>the comment field was empty"
    return
}


## Check for Naughty Input
## We filter content:allhtml instead of html because we only want to 
## check for naughty tags if the user specified html_p -MJS

if { $html_p && ![empty_string_p [ad_check_for_naughty_html $content]] } {

    set naughty_tag_list [ad_parameter_all_values_as_list NaughtyTag antispam]
    set naughty_tag_string [join $naughty_tag_list " "]
    ad_scope_return_complaint 1 "You attempted to submit one of these forbidden HTML tags: $naughty_tag_string"
    return
}




# user has input something, so continue on

# assign necessary data for insert
set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration
set originating_ip [ns_conn peeraddr]

if { [ad_parameter CommentApprovalPolicy calendar] == "open"} {
    set approved_p "t"
} else {
    set approved_p "f"
}

set query_calendar_title "select title from calendar where calendar_id = :calendar_id"

set calendar_title [db_string calendar_title $query_calendar_title]


if {[catch {ad_general_comment_add $comment_id "calendar" $calendar_id $calendar_title $content $user_id $originating_ip $approved_p $html_p ""} errmsg]} {
    
    # Oracle choked on the insert
    
    set query_count_this_comment_id "select count(*) from general_comments where comment_id = :comment_id"
    
    if { [db_string count_this_comment_id $query_count_this_comment_id] == 0 } {
	
	# there was an error with comment insert other than a duplication
	ad_scope_return_error "Error in inserting comment" "We were unable to insert your comment in the database.  Here is the error that was returned:
	<p>
	<blockquote>
	<pre>
	$errmsg
	</pre>
	</blockquote>"
	return
    }
}

db_release_unused_handles

# either we were successful in doing the insert or the user hit submit
# twice and we don't really care

ad_returnredirect "item.tcl?[export_url_scope_vars calendar_id]"

## END FILE comment-add-3.tcl

