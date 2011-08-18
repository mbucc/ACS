#
# /www/admin/news/post-new.tcl
#
# input form for the new news item
#
# Author: jkoontz@arsdigita.com March 8, 2000
#
# $Id: post-new.tcl,v 3.1 2000/03/10 23:45:54 jkoontz Exp $

set_the_usual_form_variables 0
# maybe return_url, name, scope, group_id

set db [ns_db gethandle]

# Get the group name
if { ![info exists group_id] } {
    set group_id 0
}
set group_name [database_to_tcl_string_or_null $db "select group_name from user_groups where group_id= '$group_id'"]

set page_content "
[ad_admin_header "Add Item"]
<h2>Add Item</h2>
[ad_admin_context_bar [list "index.tcl" "News"] "Add Item"]

<hr>

<blockquote>
For $scope $group_name news
</blockquote>

<form method=post action=\"post-new-2.tcl\">

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
[export_form_vars scope group_id]
</form>
[ad_admin_footer]
"
 
ns_db releasehandle $db

ns_return 200 text/html $page_content