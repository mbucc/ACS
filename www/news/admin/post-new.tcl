# /www/news/admin/post-new.tcl
#

ad_page_contract {
    input form for the new news item

    @author jkoontz@arsdigita.com
    @creation-date March 8, 2000
    @cvs-id post-new.tcl,v 3.4.2.10 2001/01/09 21:57:29 khy Exp

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
}


ad_scope_error_check

ad_scope_authorize $scope admin group_admin none


set news_item_id [db_string news_id_get "select news_item_id_sequence.nextval from dual"]

set page_content "
[ad_scope_admin_header "Add Item"]
[ad_scope_admin_page_title "Add Item"]
[ad_scope_admin_context_bar [list "" "News"] "Add Item"]

<hr>

<form method=post action=\"post-new-2\">
<table>
<tr><th>Title <td><input type=text size=40 name=title>
<tr><th>Full Story <td><textarea cols=60 rows=6 wrap=soft name=body></textarea>
<tr><th align=left>Text above is
<td><select name=html_p><option value=f>Plain Text<option value=t>HTML</select></td>
</tr>
<tr><th>Release Date <td>[philg_dateentrywidget release_date [db_string news_sysdate_get "select sysdate from dual"]]
<tr><th>Expire Date <td>[philg_dateentrywidget expiration_date [db_string news_expire_get "select sysdate + [ad_parameter DefaultStoryLife news 30] from dual"]]
</table>
<br>
<center>
<input type=\"submit\" value=\"Submit\">
</center>
[export_form_vars -sign news_item_id]
</form>
[ad_scope_admin_footer]
"

 

doc_return  200 text/html $page_content
