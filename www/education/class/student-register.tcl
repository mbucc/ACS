#
# /www/education/class/student-register.tcl
#
# user-side analogy of /education/class/admin/user-info-edit.tcl 
# allows a student to register for a class. 
#
# aileen@arsdigita.com, randyg@arsdigita.com
#
# January, 2000

# class_id, account_proc (optional) - a customizable procedure used to generate account numbers  
# account_proc2 (optional) the same customizable procedure used on student-register-2.tcl
ad_page_variables {
    class_id
    {account_proc edu_generate_student_account}
    {account_proc2 edu_process_student_account}
}

set user_id [ad_verify_and_get_user_id]

set curr_url [ns_conn url]?class_id=$class_id

if {!$user_id} {
    ad_returnredirect /register.tcl?return_url=$curr_url
    return
}

set db [ns_db gethandle]

set class_name [database_to_tcl_string $db "select class_name from edu_classes where class_id=$class_id"]


set return_string "
[ad_header "$class_name @ [ad_system_name]"]

<h2>Register for $class_name</h2>

[ad_context_bar_ws_or_index "Registration"]

<hr>
<blockquote>
<form method=post action=\"student-register-2.tcl\">
<table>
"

set email [database_to_tcl_string $db "
select email from users where user_id=$user_id"]

append return_string "
<tr><th align=right>Email:</th>
<td>$email</td></tr>
"

# get an account number or ask for user input. account_proc should signal an
# error if an account number could not be generated.
if {[catch {$account_proc $db} errmsg]} {
    ad_return_complaint 1 "<li>$errmsg"
    return
}

set selection [ns_db select $db "
select field_name, sort_key 
from user_group_type_member_fields f, ugt_member_fields_to_role_map m
where group_type='edu_class'
and m.field_id=f.member_field_id
and m.role='student'
order by sort_key"]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query

    append return_string "
    <tr>
    <th align=right>$field_name</th>"

    # if account number is not set then we assume we're getting input from user
    if {$field_name=="Student Account" && [info exists account_number]} {
	append return_string "<td>$account_number</td></tr>
	<input type=hidden name=\"$field_name\" value=$account_number>"
    } else {
	append return_string "
	<td><input type=text size=40 name=\"$field_name\"></td>
	</tr>
	"
    }
}

append return_string "
[export_form_vars user_id class_id account_number account_proc2]
<tr><th></th>
<td><input type=submit value=Register></td>
</tr>
</table>
</blockquote>
</form>
[ad_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $return_string
