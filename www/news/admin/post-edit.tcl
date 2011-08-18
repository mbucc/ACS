#
# /www/news/admin/post-edit.tcl
#
# edit form for a news item
#
# Author: jkoontz@arsdigita.com March 8, 2000
#
# $Id: post-edit.tcl,v 3.1 2000/03/10 23:45:34 jkoontz Exp $

# Note: if page is accessed through /groups pages then group_id and 
# group_vars_set are already set up in the environment by the 
# ug_serve_section. group_vars_set contains group related variables
# (group_id, group_name, group_short_name, group_admin_email, 
# group_public_url, group_admin_url, group_public_root_url,
# group_admin_root_url, group_type_url_p, group_context_bar_list and
# group_navbar_list)

set_the_usual_form_variables
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)
# maybe return_url, name
# news_item_id

ad_scope_error_check
set db [ns_db gethandle]
news_admin_authorize $db $news_item_id

set selection [ns_db 0or1row $db "
select title, body, html_p,  release_date, expiration_date, html_p
from news_items where news_items.news_item_id = $news_item_id"]
set_variables_after_query

append page_content "
[ad_scope_admin_header "Edit $title" $db ]
[ad_scope_admin_page_title "Edit $title" $db ]

[ad_scope_admin_context_bar [list "index.tcl?[export_url_scope_vars ]" "News"] "Edit Item"]

<hr>
<form method=post action=\"post-edit-2.tcl\">
[export_form_scope_vars]
<table>
<tr><th>Title <td><input type=text size=40 name=title value=\"[philg_quote_double_quotes $title]\">
<tr><th>Full Story <td><textarea cols=60 rows=6 wrap=soft name=body>[philg_quote_double_quotes $body]</textarea>
<tr><th align=left>Text above is
<td><select name=html_p>
[ad_generic_optionlist {"Plain Text" "HTML"} {"f" "t"} $html_p]
</select></td>
</tr>
<tr><th>Release Date <td>[philg_dateentrywidget release_date $release_date]
<tr><th>Expire Date <td>[philg_dateentrywidget expiration_date $expiration_date]
</table>
<br>
<center>
<input type=\"submit\" value=\"Submit\">
</center>
<input type=hidden name=news_item_id value=\"$news_item_id\">
</form>
[ad_scope_admin_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $page_content