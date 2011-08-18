# $Id: comment-add.tcl,v 3.1 2000/03/11 09:03:21 aileen Exp $
# File:     /calendar/comment-add.tcl
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

set_form_variables 0
# calendar_id
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)

ad_scope_error_check

set db [ns_db gethandle]
ad_scope_authorize $db $scope all group_member registered

set selection [ns_db 0or1row $db "select c.*
from calendar c, calendar_categories cc
where c.calendar_id = $calendar_id
and c.category_id=cc.category_id
and [ad_scope_sql cc]"]


if { $selection == "" } {
    ad_scope_return_error "Can't find calendar item" "Can't find calendar item $calendar_id" $db
    return
}

set_variables_after_query

# take care of cases with missing data

ReturnHeaders

ns_write "
[ad_scope_header "Add a comment to $title" $db]
[ad_scope_page_title "Add a Comment to $title" $db]
[ad_scope_context_bar_ws_or_index [list "index.tcl?[export_url_scope_vars]" [ad_parameter SystemName calendar "Calendar"]] [list "item.tcl?[export_url_scope_vars calendar_id]" "One Item"] "Add Comment"]

<hr>
[ad_scope_navbar]

<blockquote>
[util_maybe_convert_to_html $body $html_p]
<form action=comment-add-2.tcl method=post>
What comment  would you like to add to this item?<br>
<textarea name=content cols=50 rows=5 wrap=soft>
</textarea><br>
Text above is
<select name=html_p><option value=f>Plain Text<option value=t>HTML</select>
<br>
<center>
<input type=submit name=submit value=\"Proceed\">
</center>
[export_form_scope_vars calendar_id]
<input type=hidden name=comment_id value=\"[database_to_tcl_string $db "select general_comment_id_sequence.nextval from dual"]\">
</form>

</blockquote>
[ad_scope_footer]
"
