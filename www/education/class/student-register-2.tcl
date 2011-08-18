#
# /www/education/class/student-register.tcl
#
# user-side analogy of /education/class/admin/user-info-edit.tcl allows a student 
# to register for a class. 
#
# aileen@arsdigita.com, randyg@arsdigita.com
#
# January, 2000

# $field_names from user_group_type_member_fields where role in 
# ugt_member_fields_to_role_map = 'student'
# user_id class_id account_proc2 account_number (optional) 

set_the_usual_form_variables

set handles [edu_get_two_db_handles]
set db [lindex $handles 0]
set db_sub [lindex $handles 1]


set selection [ns_db select $db "
select field_name, sort_key 
from user_group_type_member_fields f, ugt_member_fields_to_role_map m
where group_type='edu_class'
and m.field_id=f.member_field_id
and m.role='student'
order by sort_key"]

set mail_string ""

ns_db dml $db_sub "begin transaction"

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    
    # this is just to be safe. we can't assume that student info isn't
    # populated in places other than this script. so check if the values
    # already exist
    ns_db dml $db_sub "
    delete from user_group_member_field_map
    where user_id=$user_id 
    and group_id=$class_id 
    and field_name='[DoubleApos $field_name]'"

    ns_db dml $db_sub "
    insert into user_group_member_field_map
    (field_name, user_id, group_id, field_value)
    values
    ('[DoubleApos $field_name]', $user_id, $class_id, '[DoubleApos [set $field_name]]')"

    if {$field_name!="Student Account"} {
	append mail_string "\n\n
	$field_name: [set $field_name]"
    } else {
	set email_extra [$account_proc2 $db_sub [set $field_name]]
    }
}

# add the student to the class if not already in:
if {[database_to_tcl_string $db_sub "select count(*) from user_group_map where user_id=$user_id and group_id=$class_id"]==0} {
    ns_db dml $db_sub "insert into user_group_map 
    (group_id, user_id, role, registration_date, mapping_user, mapping_ip_address) 
    values 
    ($class_id, $user_id, 'student', sysdate, $user_id, '[ns_conn peeraddr]')"
}

ns_db dml $db_sub "end transaction"



set class_name [database_to_tcl_string $db "select class_name from edu_classes where class_id=$class_id"]

set email [database_to_tcl_string $db "select email from users where user_id=$user_id"]

ns_sendmail $email "registration-robot" "New Registration for $class_name" "You have successfully registered for $class_name with the following info: 
$mail_string \n\n
$email_extra
"

set return_string "
[ad_header "$class_name @ [ad_system_name]"]

<h2>Registration for $class_name Successful!</h2>

[ad_context_bar_ws_or_index "Registration"]

<hr>
You have successfully registered for $class_name. A confirmation email has been sent to your email address $email.
<p>
<a href=/index.adp>Return to the class home page</a>
[ad_footer]
"

ns_db releasehandle $db
ns_db releasehandle $db_sub


ns_return 200 text/html $return_string
