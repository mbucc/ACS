# $Id: custom-field-add-3.tcl,v 3.0.4.1 2000/04/28 15:08:48 carsten Exp $
set_the_usual_form_variables

# field_identifier, field_name, default_value, column_type

# we need them to be logged in
set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    
    set return_url "[ns_conn url]?[export_entire_form_as_url_vars]"

    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

# if the column type is boolean, we want to add a (named) check constraint at the end
if { $column_type == "char(1)" } {
    set end_of_alter ",\nconstraint ${field_identifier}_constraint check ($field_identifier in ('t', 'f'))"
} else {
    set end_of_alter ""
}

set db [ns_db gethandle]

if { [database_to_tcl_string $db "select count(*) from ec_custom_product_fields where field_identifier='$QQfield_identifier'"] > 0 } {
    # then they probably just hit submit twice, so send them to custom-fields.tcl
    ad_returnredirect "custom-fields.tcl"
}

set audit_fields "last_modified, last_modifying_user, modified_ip_address"
set audit_info "sysdate, '$user_id', '[DoubleApos [ns_conn peeraddr]]'"

set insert_statement "insert into ec_custom_product_fields
(field_identifier, field_name, default_value, column_type, $audit_fields)
values
('$QQfield_identifier', '$QQfield_name', '$QQdefault_value', '$QQcolumn_type', $audit_info)"

if [catch { ns_db dml $db $insert_statement } errmsg] {
    ad_return_error "Unable to Add Field" "Sorry, we were unable to add the field you requested.  Here's the error message: <blockquote><pre>$errmsg</pre></blockquote>"
    return
}

# have to alter ec_custom_product_field_values, the corresponding audit
# table, and the corresponding trigger

set alter_statement "alter table ec_custom_product_field_values add (
    $field_identifier $column_type$end_of_alter
)"

if [catch { ns_db dml $db $alter_statement } errmsg] {
    # this means we were unable to add the column to ec_custom_product_field_values, so undo the insert into ec_custom_product_fields
    ns_db dml $db "delete from ec_custom_product_fields where field_identifier='$QQfield_identifier'"
    ad_return_error "Unable to Add Field" "Sorry, we were unable to add the field you requested.  The error occurred when adding the column $field_identifier to ec_custom_product_field_values, so we've deleted the row containing $field_identifier from ec_custom_product_fields as well (for consistency).  Here's the error message: <blockquote><pre>$errmsg</pre></blockquote>"
    return
}

# 1999-08-10: took out $end_of_alter because the constraints don't
# belong in the audit table

set alter_statement_2 "alter table ec_custom_p_field_values_audit add (
    $field_identifier $column_type
)"

if [catch {ns_db dml $db $alter_statement_2} errmsg] {
    # this means we were unable to add the column to ec_custom_p_field_values_audit, so undo the insert into ec_custom_product_fields and the alteration to ec_custom_product_field_values
    ns_db dml $db "delete from ec_custom_product_fields where field_identifier='$QQfield_identifier'"
    ns_db dml $db "alter table ec_custom_product_field_values drop column $field_identifier"
    ad_return_error "Unable to Add Field" "Sorry, we were unable to add the field you requested.  The error occurred when adding the column $field_identifier to ec_custom_p_field_values_audit, so we've dropped that column from ec_custom_product_field_values and we've deleted the row containing $field_identifier from ec_custom_product_fields as well (for consistency).  Here's the error message: <blockquote><pre>$errmsg</pre></blockquote>"
    return
}



# determine what the new trigger should be
set new_trigger_beginning "create or replace trigger ec_custom_p_f_values_audit_tr
before update or delete on ec_custom_product_field_values
for each row
begin
	insert into ec_custom_p_field_values_audit ("

set trigger_column_list [list]
for {set i 0} {$i < [ns_column count $db ec_custom_product_field_values]} {incr i} {
    lappend trigger_column_list [ns_column name $db ec_custom_product_field_values $i]
}

set new_trigger_columns [join $trigger_column_list ", "]

set new_trigger_middle ") values ("

set new_trigger_values ":old.[join $trigger_column_list ", :old."]"

set new_trigger_end ");
end;
"

set new_trigger "$new_trigger_beginning
$new_trigger_columns
$new_trigger_middle
$new_trigger_values
$new_trigger_end"

ns_db dml $db "drop trigger ec_custom_p_f_values_audit_tr"
ns_db dml $db $new_trigger

ad_returnredirect "custom-fields.tcl"
