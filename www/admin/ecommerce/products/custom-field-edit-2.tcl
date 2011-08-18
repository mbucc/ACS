# $Id: custom-field-edit-2.tcl,v 3.0.4.1 2000/04/28 15:08:49 carsten Exp $
set_the_usual_form_variables

# field_identifier, field_name, default_value, column_type, old_column_type

# we need them to be logged in
set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    
    set return_url "[ns_conn url]?[export_entire_form_as_url_vars]"

    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

set db [ns_db gethandle]

# I'm not going to let them change from a non-boolean column type to a boolean
# one because it's too complicated adding the constraint (because first you
# change the column type and then you try to add the constraint, but if you
# fail when you add the constraint, you've still changed the column type (there's no
# rollback when you're altering tables), and in theory I could then change the
# column type back to the original one if the constraint addition fails, but
# what if that fails, so I'm just not going to allow it).

if { $old_column_type != "char(1)" && $column_type == "char(1)"} {
    ad_return_complaint 1 "<li>The Kind of Information cannot be changed from non-boolean to boolean."
    return
}

ns_db dml $db "begin transaction"

ns_db dml $db "update ec_custom_product_fields
set field_name = '$QQfield_name',
default_value = '$QQdefault_value',
column_type='$QQcolumn_type', 
last_modified=sysdate, 
last_modifying_user='$user_id', 
modified_ip_address='[DoubleApos [ns_conn peeraddr]]'
where field_identifier = '$QQfield_identifier'"

if { $column_type != $old_column_type } {

    # if the old column_type is a boolean, then let's drop the old constraint
    if { $old_column_type == "char(1)" } {
	ns_db dml $db "alter table ec_custom_product_field_values drop constraint ${field_identifier}_constraint"
    }

    set alter_table_statement "alter table ec_custom_product_field_values modify (
    $field_identifier $column_type
)"

    if [catch { ns_db dml $db $alter_table_statement } errmsg] {
	ad_return_complaint 1 "<li>The modification of Kind of Information failed.  Here is the error message that Oracle gave us:<blockquote>$errmsg</blockquote>"
	return
    }

}

ns_db dml $db "end transaction"

ad_returnredirect "custom-fields.tcl"
