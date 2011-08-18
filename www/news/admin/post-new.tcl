#
# /www/news/admin/post-new.tcl
#
# input form for the new news item
#
# Author: jkoontz@arsdigita.com March 8, 2000
#
# $Id: post-new.tcl,v 3.1 2000/03/10 23:45:34 jkoontz Exp $

# Note: if page is accessed through /groups pages then group_id and 
# group_vars_set are already set up in the environment by the 
# ug_serve_section. group_vars_set contains group related variables
# (group_id, group_name, group_short_name, group_admin_email, 
# group_public_url, group_admin_url, group_public_root_url,
# group_admin_root_url, group_type_url_p, group_context_bar_list and
# group_navbar_list)

set_the_usual_form_variables 0
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)
# maybe return_url, name

ad_scope_error_check
set db [ns_db gethandle]
ad_scope_authorize $db $scope admin group_admin none


append page_content "
[ad_scope_admin_header "Add Item" $db ]
[ad_scope_admin_page_title "Add Item" $db ]

[ad_scope_admin_context_bar [list "index.tcl?[export_url_scope_vars]" "News"] "Add Item"]

<hr>

<form method=post action=\"post-new-2.tcl\">
[export_form_scope_vars]

<table>
<tr><th>Title <td><input type=text size=40 name=title>
<tr><th>Full Story <td><textarea cols=60 rows=6 wrap=soft name=body></textarea>
<tr><th align=left>Text above is
<td><select name=html_p><option value=f>Plain Text<option value=t>HTML</select></td>
</tr>
<tr><th>Release Date <td>[philg_dateentrywidget release_date [database_to_tcl_string $db "select sysdate from dual"]]
<tr><th>Expire Date <td>[philg_dateentrywidget expiration_date [database_to_tcl_string $db "select sysdate + [ad_parameter DefaultStoryLife news 30] from dual"]]
</table>
<br>
<center>
<input type=\"submit\" value=\"Submit\">
</center>
<input type=hidden name=news_item_id value=\"[database_to_tcl_string  $db "select news_item_id_sequence.nextval from dual"]\">
</form>
[ad_scope_admin_footer]
"
 
ns_db releasehandle $db

ns_return 200 text/html $page_content