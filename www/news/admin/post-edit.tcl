# /www/news/admin/post-edit.tcl
#

ad_page_contract {
    edit form for a news item

    @author jkoontz@arsdigita.com
    @creation-date March 8, 2000
    @cvs-id post-edit.tcl,v 3.3.2.9 2000/09/22 01:38:59 kevin Exp

    Note: if page is accessed through /groups pages then group_id and 
    group_vars_set are already set up in the environment by the 
    ug_serve_section. group_vars_set contains group related variables
    (group_id, group_name, group_short_name, group_admin_email, 
    group_public_url, group_admin_url, group_public_root_url,
    group_admin_root_url, group_type_url_p, group_context_bar_list and
    group_navbar_list)
} {
    scope:optional
    user_id:integer,optional
    group_id:integer,optional
    on_which_group:integer,optional
    on_what_id:integer,optional
    return_url:optional
    name:optional
    news_item_id:integer,notnull
}


ad_scope_error_check

news_admin_authorize $news_item_id

db_0or1row news_item_get "
select title, body, html_p, release_date, expiration_date, html_p
from news_items where news_items.news_item_id = :news_item_id"
db_release_unused_handles


set page_content "
[ad_scope_admin_header "Edit $title"]
[ad_scope_admin_page_title "Edit $title"]
[ad_scope_admin_context_bar [list "?[export_url_vars ]" "News"] "Edit Item"]

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
[ad_scope_admin_footer]
"



doc_return  200 text/html $page_content
