# /www/admin/news/post-edit.tcl
#

ad_page_contract {
    input form for editing a news item

    @author jkoontz@arsdigita.com
    @creation-date March 8, 2000
    @cvs-id post-edit.tcl,v 3.3.2.6 2000/09/22 01:35:44 kevin Exp

    Note: if this page is accessed from the group pages (scope=group), then 
    group_id, group_name, short_name and admin_email are already
    set up in the environment by the ug_serve_section
} {
    return_url:optional
    name:optional
    news_item_id:integer,notnull
}


db_0or1row news_item_get "
select title, body, html_p,  release_date, expiration_date
from news_items where news_item_id = :news_item_id"

db_release_unused_handles


set page_content "
[ad_admin_header "Edit $title"]
<h2>Edit $title</h2>
[ad_admin_context_bar [list "" "News"] "Edit Item"]
<hr>
<form method=post action=\"post-edit-2\">

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



doc_return  200 text/html $page_content