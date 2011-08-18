#
# /www/education/class/admin/users/info-edit-3.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this page puts the new user information into the database
#

set_the_usual_form_variables

# user_id field_names from user_group_type_member_fields for edu_class

set db [ns_db gethandle]

set id_list [edu_group_security_check $db edu_class "Manage Users"]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]

set user_fields [database_to_tcl_list $db "
select distinct mf.field_name
from user_group_type_member_fields mf,
     user_group_map map
where map.user_id = $user_id
  and (mf.role is null or lower(mf.role) = lower(map.role))
  and map.group_id = $class_id
  and mf.group_type='edu_class'"]

ns_db dml $db "begin transaction"


foreach field $user_fields {
    
    if {[info exists $field]} {
	# we try to update it and then see how many
	# rows were updated.  If it is zero, then we insert
	ns_db dml $db "update user_group_member_field_map
                       set field_value = '[DoubleApos [set $field]]'
                       where user_id = $user_id
                         and group_id = $class_id
                         and field_name = '[DoubleApos $field]'"

	set n_updated_rows [ns_ora resultrows $db]

	if {$n_updated_rows == 0} {
	    # we want to insert it
	    ns_db dml $db "
	    insert into user_group_member_field_map
	    (field_name, user_id, group_id, field_value)
	    values
	    ('[DoubleApos $field]', $user_id, $class_id, '[DoubleApos [set $field]]')"
	}
    }
}

ns_db dml $db "end transaction"

ad_returnredirect "one.tcl?user_id=$user_id"

