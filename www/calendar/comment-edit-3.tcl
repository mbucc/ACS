# www/calendar/comment-edit-3.tcl
ad_page_contract {
    Performs database update to an existing general comment on a calendar item
    
    Number of queries: 1
    Number of inserts: 2
    
    @author Philip Greenspun (philg@mit.edu)
    @author Sarah Ahmed (ahmeds@arsdigita.com)
    @creation-date 1998-11-18
    @cvs-id comment-edit-3.tcl,v 3.2.6.5 2000/07/21 03:59:01 ron Exp
    @last-modified 2000-07-12
    @last-modified-by Michael Shurpik (mshurpik@arsdigita.com)
} {
    comment_id:integer
    html_p:notnull
    content:allhtml
    {scope public}
    {user_id ""}
    {group_id ""}
    {on_what_id ""}
    {on_which_group ""}
}


## Original comments:

# comment-edit-3.tcl,v 3.2.6.5 2000/07/21 03:59:01 ron Exp
# File:     /calendar/comment-edit-3.tcl
# Date:     1998-11-18
# Contact:  philg@mit.edu, ahmeds@arsdigita.com
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)


## Original set_form comments:

# comment_id, content, html_p
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)


if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

ad_scope_error_check


ad_scope_authorize $scope all group_member registered


# check for bad input
if  {![info exists content] || [empty_string_p $content] } { 
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



set query_get_comment "
select calendar_id, general_comments.user_id as comment_user_id
from calendar, general_comments
where comment_id = :comment_id
and calendar.calendar_id = general_comments.on_what_id
"

if { ![db_0or1row get_comment $query_get_comment] } {

    ad_scope_return_error "Can't find comment" "Can't find comment #$comment_id"
    return
}



## Use of ad_verify vs. ad_get_user_id is NOT consistent in this module,
## unless I'm missing something. -MJS

set user_id [ad_verify_and_get_user_id]

# check to see if ther user was the orginal poster
if {$user_id != $comment_user_id} {
    ad_scope_return_complaint 1 "<li>You can not edit this entry because you did not post it"
    return
}



db_transaction { 
    
    set dml_insert_audit "insert into general_comments_audit
    (comment_id, user_id, ip_address, audit_entry_time, modified_date, content)
    select comment_id, user_id, '[ns_conn peeraddr]', 
    sysdate, modified_date, content from general_comments where comment_id = :comment_id"
    
    # insert into the audit table
    db_dml insert_audit $dml_insert_audit
    

    ## The New Database API says not to use -bind with LOBS.  As an example, they show that
    ## version_id = :version_id is wrong, whereas version_id = $version_id is correct.
    ## So don't yell. This is the only way it would work. -MJS

    set dml_update_comment "update general_comments
    set content = empty_clob(), html_p = '$html_p'
    where comment_id = $comment_id returning content into :1" 
    
    db_dml update_comment $dml_update_comment -clobs [list $content]
    
    db_release_unused_handles
    
} on_error {
    
    # there was some other error with the comment update
    ad_scope_return_error "Error updating comment" "We couldn't update your comment. Here is what the database returned:
    <p>
    <blockquote>
    <pre>
    $errmsg
    </pre>
    </blockquote>
    "
    return
}


ad_returnredirect "item.tcl?[export_url_scope_vars calendar_id]"

## END FILE comment-edit-3.tcl
