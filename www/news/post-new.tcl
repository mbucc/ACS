#
# /www/news/post-new.tcl
#
# posts new news item
#
# Author: jkoontz@arsdigita.com March 8, 2000
#
# $Id: post-new.tcl,v 3.2.2.1 2000/04/28 15:11:15 carsten Exp $

# Note: if page is accessed through /groups pages then group_id and 
# group_vars_set are already set up in the environment by the 
# ug_serve_section. group_vars_set contains group related variables
# (group_id, group_name, group_short_name, group_admin_email, 
# group_public_url, group_admin_url, group_public_root_url,
# group_admin_root_url, group_type_url_p, group_context_bar_list and
# group_navbar_list)

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set_the_usual_form_variables 0
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)
# maybe return_url, name

ad_scope_error_check

set db [ns_db gethandle]
set user_id [ad_scope_authorize $db $scope all all all ]

# Get the group name
if { ![info exists group_id] } {
    set group_id 0
}
set group_name [database_to_tcl_string_or_null $db "select group_name from user_groups where group_id= '$group_id'"]

if { [string match $scope "public"] } {
    set group_name "Public"
}

if { $user_id == 0 } {
    ad_returnredirect "/register/index.tcl?[export_url_scope_vars]&return_url=[ns_urlencode [ns_conn url]]"
    return
}

if { [ad_parameter ApprovalPolicy news] == "open"} {
    set verb "Post"
} elseif { [ad_parameter ApprovalPolicy news] == "wait"} {
    set verb "Suggest"
} else {
    ad_returnredirect "index.tcl?[export_url_scope_vars]"
    return
}

set page_content "
[ad_scope_header "$verb News" $db]
[ad_scope_page_title "$verb News" $db]

for [ad_site_home_link]
<hr>
[ad_scope_navbar]

<blockquote>
For $group_name News
</blockquote>

<form method=post action=\"post-new-2.tcl\">
[export_form_vars return_url]
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
</form>
[ad_scope_footer]
"
 
ns_db releasehandle $db

ns_return 200 text/html $page_content