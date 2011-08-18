#
# /www/admin/news/post-edit.tcl
#
# input form for editing a news item
#
# Author: jkoontz@arsdigita.com March 8, 2000
#
# $Id: post-edit.tcl,v 3.1 2000/03/10 23:45:54 jkoontz Exp $

# Note:     if this page is accessed from the group pages (scope=group), then 
#           group_id, group_name, short_name and admin_email are already
#           set up in the environment by the ug_serve_section

set_the_usual_form_variables 0

# maybe return_url, name
# news_item_id

set db [ns_db gethandle]

set selection [ns_db 0or1row $db "
select title, body, html_p,  release_date, expiration_date
from news_items where news_item_id = $news_item_id"]
set_variables_after_query

set page_content "
[ad_admin_header "Edit $title"]
<h2>Edit $title</h2>
[ad_admin_context_bar [list "index.tcl" "News"] "Edit Item"]
<hr>
<form method=post action=\"post-edit-2.tcl\">

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
[ad_admin_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $page_content