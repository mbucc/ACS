# $Id: group-info-edit-2.tcl,v 3.0.4.1 2000/04/28 15:09:27 carsten Exp $
set_the_usual_form_variables

# group_id, group_name

set db [ns_db gethandle]

set group_type [database_to_tcl_string $db "select group_type, group_name
from user_groups where group_id = $group_id"]

set helper_table_name [ad_user_group_helper_table_name [DoubleApos $group_type]]

# let's use the utilities.tcl procedure util_prepare_insert
# for this we need to produce an ns_conn form-style structure

set helper_fields [ns_set new]

foreach helper_column [database_to_tcl_list $db "select column_name from user_group_type_fields where group_type = '[DoubleApos $group_type]'"] {
    if [info exists $helper_column] {
	ns_set put $helper_fields $helper_column [set $helper_column]
    }
}

if { [ns_set size $helper_fields] > 0 } {
    set update_for_helper_table [util_prepare_update $db $helper_table_name group_id $group_id $helper_fields]
    
    ns_db dml $db  $update_for_helper_table
}



ad_returnredirect "group.tcl?group_id=$group_id"

