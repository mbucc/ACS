ad_page_contract {
    @cvs-id user-class-edit.tcl,v 3.2.2.3.2.3 2000/09/22 01:36:25 kevin Exp
} {
    user_class_id:integer,notnull
}


db_1row admin_users_user_class_info_select "select name,
sql_description, sql_post_select, description
from user_classes
where user_class_id = :user_class_id"


set page_content "
[ad_admin_header "Edit $name"]

<h3>Edit $name</h3>

[ad_admin_context_bar [list "index.tcl" "Users"] [list "action-choose.tcl?[export_url_vars user_class_id]" "$name" ] "Edit"]

<hr>

<form action=user-class-edit-2 method=post>
[export_form_vars user_class_id]
<table>
<tr><th align=right>Name:</th><td><input type=text name=name maxlength=100 [export_form_value name]></td></tr>

<tr><th align=right>Description:</th><td><textarea cols=40 rows=4 name=description>[ns_quotehtml $description]</textarea></td></tr>

<tr><th align=right valign=top>SQL description:</th><td>User who<br><textarea cols=40 rows=4 name=sql_description>[ns_quotehtml $sql_description]</textarea></td></tr>

<tr><th align=right valign=top>SQL:</th><td>
select users(*) <br>
<textarea cols=40 rows=4 name=sql_post_select>[ns_quotehtml $sql_post_select]</textarea>
</td></tr>
</table>
<center>
<input type=submit name=submit value=\"Submit\">
</center>
</form>
[ad_admin_footer]"



doc_return  200 text/html $page_content
