# add news item for a group -- class, dept, or team
# /education/news/news-add.tcl
# aileen@mit.edu, randyg@mit.edu
# feb 2000

ad_page_variables {
    group_id
}

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

ns_db releasehandle $db

ns_return 200 text/html "
[ad_scope_header "$verb News" $db]
[ad_scope_page_title "$verb News" $db]

for [ad_site_home_link]
<hr>
[ad_scope_navbar]

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
</form>
[ad_scope_footer]
"
 
