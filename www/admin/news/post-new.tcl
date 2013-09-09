# /www/admin/news/post-new.tcl
#

ad_page_contract {
    input form for the new news item

    @author jkoontz@arsdigita.com
    @creation-date March 8, 2000
    @cvs-id post-new.tcl,v 3.5.2.9 2001/01/09 22:02:07 khy Exp
} {
    return_url:optional
    name:optional
    scope:optional
    {group_id:integer "0"}
}



set group_name [db_string news_groupname_get "select group_name from user_groups 
where group_id= :group_id" -default ""]

switch $scope {
    group   {set pretty_scope "Group"}
    public {set pretty_scope "Public"}
    all_users {set pretty_scope "All users"}
    registered_users {set pretty_scope "All registered users"} 
    default {set pretty_scope ""}
}

set news_item_id [db_string news_id_get "select news_item_id_sequence.nextval from dual"]

set page_content "
[ad_admin_header "Add Item"]
<h2>Add Item</h2>
[ad_admin_context_bar [list "" "News"] "Add Item"]

<hr>

<blockquote>
For $pretty_scope $group_name news
</blockquote>

<form method=post action=\"post-new-2\">

<table>
<tr><th>Title <td><input type=text size=40 name=title>
<tr><th>Full Story <td><textarea cols=60 rows=6 wrap=soft name=body></textarea>
<tr><th align=left>Text above is
<td><select name=html_p><option value=f>Plain Text<option value=t>HTML</select></td>
</tr>
<tr><th>Release Date <td>[ad_dateentrywidget release_date [db_string news_sysdate_get "select sysdate from dual"]]
<tr><th>Expire Date <td>[ad_dateentrywidget expiration_date [db_string news_expiredate_get "select sysdate + [ad_parameter DefaultStoryLife news 30] from dual"]]
</table>
<br>
<center>
<input type=\"submit\" value=\"Submit\">
</center>
[export_form_vars -sign news_item_id]
[export_form_vars scope group_id]
</form>
[ad_admin_footer]
"

 

doc_return  200 text/html $page_content
