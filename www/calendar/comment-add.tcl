# www/calendar/comment-add.tcl
ad_page_contract {
    Begins the three-stage process of adding a General Comment to a calendar item

    Number of queries: 2

    @author xxx
    @creation-date unknown
    @cvs-id comment-add.tcl,v 3.2.6.8 2001/01/10 16:42:26 khy Exp
    @last-modified 2000-07-12
    @last-modified-by Michael Shurpik (mshurpik@arsdigita.com)
} {
    calendar_id:integer
    {scope public}
    {user_id ""}
    {group_id ""}
    {on_what_id ""}
    {on_which_group ""}
}

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

ad_maybe_redirect_for_registration


ad_scope_error_check

ad_scope_authorize $scope all group_member registered

set query_calendar_entries "
select c.title, c.body, c.html_p 
from calendar c, calendar_categories cc
where c.calendar_id = :calendar_id
and c.category_id=cc.category_id
and [ad_scope_sql cc]
"

if {![db_0or1row calendar_entries $query_calendar_entries]} {

    ad_scope_return_error "Can't find calendar item" "Can't find calendar item $calendar_id"
    return

}

set query_next_comment_id "select general_comment_id_sequence.nextval from dual"

set comment_id [db_string next_comment_id $query_next_comment_id]

db_release_unused_handles

# take care of cases with missing data

set page_content "
[ad_scope_header "Add a comment to $title"]
[ad_scope_page_title "Add a Comment to $title"]
[ad_scope_context_bar_ws_or_index [list "index.tcl?[export_url_scope_vars]" [ad_parameter SystemName calendar "Calendar"]] [list "item.tcl?[export_url_scope_vars calendar_id]" "One Item"] "Add Comment"]

<hr>
[ad_scope_navbar]

<blockquote>
[util_maybe_convert_to_html $body $html_p]
<form action=comment-add-2 method=post>
What comment would you like to add to this item?<br>
<textarea name=content cols=50 rows=5 wrap=soft>
</textarea><br>
Text above is
<select name=html_p><option value=f>Plain Text<option value=t>HTML</select>
<br>
<center>
<input type=submit name=submit value=\"Proceed\">
</center>
[export_form_scope_vars calendar_id]
[export_form_vars -sign comment_id]

</form>

</blockquote>
[ad_scope_footer]
"


doc_return  200 text/html $page_content

## END FILE comment-add.tcl



