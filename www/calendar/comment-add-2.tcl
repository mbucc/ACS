# www/calendar/comment-add-2.tcl
ad_page_contract {
    Phase two - Confirmation -  
    of the three-step process to add a General Comment to a calendar item
    
    Number of queries: 1

    @author Philip Greenspun (philg@mit.edu)
    @author Sarah Ahmed (ahmeds@arsdigita.com)
    @creation-date 1998-11-18
    @cvs-id comment-add-2.tcl,v 3.2.6.9 2001/01/10 16:42:05 khy Exp
    @last-modified 2000-07-12
    @last-modified-by Michael Shurpik (mshurpik@arsdigita.com)
} {
    calendar_id:integer
    comment_id:verify,naturalnum,integer
    html_p:notnull
    content:allhtml
    {scope public}
    {user_id ""}
    {group_id ""}
    {on_what_id ""}
    {on_which_group ""}
}



## Original Comments:

# comment-add-2.tcl,v 3.2.6.9 2001/01/10 16:42:05 khy Exp
# File:     /calendar/comment-add-2.tcl
# Date:     1998-11-18
# Contact:  philg@mit.edu, ahmeds@arsdigita.com
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)



if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

ad_maybe_redirect_for_registration

## Original set_form comments:

# calendar_id, content, comment_id, html_p
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)


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

set query_calendar_title "select title from calendar where calendar_id=:calendar_id"

set calendar_title [db_string calendar_title $query_calendar_title]

db_release_unused_handles

set page_content "
[ad_scope_header "Confirm comment on <i>$calendar_title</i>"]
[ad_scope_page_title "Confirm comment"]
[ad_scope_context_bar_ws_or_index [list "index.tcl?[export_url_scope_vars]" [ad_parameter SystemName calendar "Calendar"]] [list "item.tcl?[export_url_scope_vars calendar_id]" "One Item"] "Confirm Comment"]


<hr>
[ad_scope_navbar]

The following is your comment as it would appear on the page <i>$calendar_title</i>.
If it looks incorrect, please use the back button on your browser to return and
correct it.  Otherwise, press \"Continue\".
<p>
<blockquote>"

if { [info exists html_p] && $html_p == "t" } {
    
    append page_content "$content
    </blockquote>
    Note: if the story has lost all of its paragraph breaks then you
    probably should have selected \"Plain Text\" rather than HTML.  Use
    your browser's Back button to return to the submission form.
    "

} else {

    append page_content "[util_convert_plaintext_to_html $content]
    </blockquote>

    Note: if the story has a bunch of visible HTML tags then you probably
    should have selected \"HTML\" rather than \"Plain Text\".  Use your
    browser's Back button to return to the submission form.  " 
}


append page_content "

<form action=comment-add-3 method=post>
<center>
<input type=submit name=submit value=\"Confirm\">
</center>
[export_form_scope_vars content calendar_id html_p]
[export_form_vars -sign comment_id]
</form>
[ad_scope_footer]
"

doc_return  200 text/html $page_content

## END FILE comment-add-2.tcl



