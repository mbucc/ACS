# $Id: restore-one-id.tcl,v 3.0.4.1 2000/04/28 15:08:34 carsten Exp $
# Jesse 7/17
# Tries to restore from the audit table to the main table
# for one id in the id_column

set_the_usual_form_variables
# id, id_column, audit_table_name, main_table_name, rowid

# we need them to be logged in
set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    
    set return_url "[ns_conn url]?[export_entire_form_as_url_vars]"

    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

# we have to generate audit information
set audit_fields "last_modified, last_modifying_user, modified_ip_address"
set audit_info "sysdate, '$user_id', '[DoubleApos [ns_conn peeraddr]]'"

set db [ns_db gethandle]

set sql_insert ""
set result "The $main_table_name table is not supported at this time."

# Get all values from the selected row of the audit table
set selection [ns_db 1row $db "select * from $audit_table_name where rowid = '$rowid'"]
set_variables_after_query

# ss_subcategory_features
if { [string compare $main_table_name "ss_subcategory_features"] == 0 } {
    set sql_insert "insert into $main_table_name (
feature_id,
subcategory_id,
feature_name,
recommended_p,
feature_description,
sort_key,
filter_p,
comparison_p,
feature_list_p,
$audit_fields
) values (
'[DoubleApos $feature_id]',
'[DoubleApos $subcategory_id]',
'[DoubleApos $feature_name]',
'[DoubleApos $recommended_p]',
'[DoubleApos $feature_description]',
'[DoubleApos $sort_key]',
'[DoubleApos $filter_p]',
'[DoubleApos $comparison_p]',
'[DoubleApos $feature_list_p]',
$audit_info
)"

}

# ss_product_feature_map
if { [string compare $main_table_name "ss_product_feature_map"] == 0 } {
    set sql_insert ""
}

if { ![empty_string_p $sql_insert] } {
    if [catch { set result [ns_db dml $db $sql_insert] } errmsg] {
	set result $errmsg
    }
}

ns_return 200 text/html "
[ss_new_staff_header "Restore of $id_column $id"]
[ss_staff_context_bar "Restore Data"]

<h3>Restore of $main_table_name</h3>
For a the SQL insert
<blockquote>
$sql_insert
</blockquote>
This result was obtained
<blockquote>
$result
</blockquote>
[ls_admin_footer]"
