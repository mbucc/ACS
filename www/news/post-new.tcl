# /www/news/post-new.tcl
#

ad_page_contract {
    posts new news item

    @author jkoontz@arsdigita.com
    @creation-date March 8, 2000
    @cvs-id post-new.tcl,v 3.7.2.11 2000/09/22 01:38:57 kevin Exp

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
    {group_id:integer 0}
    on_which_group:integer,optional
    on_what_id:integer,optional
    return_url:optional
    name:optional
}


if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

ad_scope_error_check


set user_id [ad_scope_authorize $scope all all all ]

set group_name [db_string news_group_get \
	"select group_name from user_groups where group_id = :group_id" -default ""]

if { [string match $scope "public"] } {
    set group_name "Public"
}

if { $user_id == 0 } {
    ad_returnredirect "/register/?[export_url_vars]&return_url=[ns_urlencode [ns_conn url]]"
    return
}

if { [info exists scope] && [string match $scope "group"] } {
    set approval_policy [ad_parameter GroupScopeApprovalPolicy news [ad_parameter ApprovalPolicy news]]
}  else {
    set approval_policy [ad_parameter ApprovalPolicy news]
}

if { $approval_policy == "open" } {
    set verb "Post"
} elseif { $approval_policy == "wait"} {
    set verb "Suggest"
} else {
    ad_returnredirect "?[export_url_vars]"
    return
}

set page_content "
[ad_scope_header "$verb News"]
[ad_scope_page_title "$verb News"]

for [ad_site_home_link]
<hr>
[ad_scope_navbar]

<blockquote>
For $group_name News
</blockquote>

<form method=post action=\"post-new-2\">
[export_form_vars return_url]

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
</form>
[ad_scope_footer]
"
 


doc_return  200 text/html $page_content

