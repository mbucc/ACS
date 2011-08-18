# $Id: extras-upload-2.tcl,v 3.0 2000/02/06 03:20:06 ron Exp $
# This file updates ec_custom_product_field_values (as opposed to inserting
# new rows) because upload*.tcl (which are to be run before extras-upload*.tcl)
# insert rows into ec_custom_product_field_values (with everything empty except
# product_id and the audit columns) when they insert the rows into ec_products
# (for consistency with add*.tcl).

set_the_usual_form_variables
# csv_file

if { ![info exists csv_file] } {
    ad_return_error "Missing CSV File" "You must input the name of the .csv file on your local hard drive."
    return
}

set user_id [ad_get_user_id]
set ip [ns_conn peeraddr]


ReturnHeaders

ns_write "[ad_admin_header "Uploading Extras"]

<h2>Uploading Extras</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Products"] "Uploading Extras"]

<hr>

"

set unix_file_name [ns_queryget csv_file.tmpfile]
#set unix_file_name "[ns_info pageroot]/$csv_file"

set db [ns_db gethandle]

if { ![file readable $unix_file_name] } {
    ns_write "Cannot read file $unix_file_name"
    return
}

ns_write "<pre>
"

set csvfp [open $unix_file_name]

set count 0
while { [ns_getcsv $csvfp elements] != -1 } {
    incr count
    if { $count == 1 } {
	# first time thru, we grab the number of columns and their names
	set number_of_columns [llength $elements]
	set columns $elements
	set product_id_column [lsearch -exact $columns "product_id"]
    } else {
	# this line is a product
# (this file used to insert rows into ec_custom_product_field_values, but
# now that is done in upload-2.tcl, so we need to update instead)
# 	set columns_sql "insert into ec_custom_product_field_values (last_modified, last_modifying_user, modified_ip_address "
# 	set values_sql " values (sysdate, $user_id, '$ip' "
# 	for { set i 0 } { $i < $number_of_columns } { incr i } {
# 	    append columns_sql ", [lindex $columns $i]"
# 	    append values_sql ", '[DoubleApos [lindex $elements $i]]'"
# 	}
# 	set sql "$columns_sql ) $values_sql )"

	set sql "update ec_custom_product_field_values set last_modified=sysdate, last_modifying_user=$user_id, modified_ip_address='$ip'"

	for { set i 0 } { $i < $number_of_columns } { incr i } {
	    if { $i != $product_id_column } {
		append sql ", [lindex $columns $i]='[DoubleApos [lindex $elements $i]]'"
	    }
	}
	append sql "where product_id=[lindex $elements $product_id_column]"

	if { [catch {ns_db dml $db $sql} errmsg] } {
	    append bad_products_sql "$sql\n"
	    ns_write "<font color=red>FAILURE!</font> SQL: $sql<br>\n"
	} else {
	    ns_write "Success!<br>\n"
	}
    }
}

ns_write "</pre>
<p>Done loading [ec_decode $count "0" "0" [expr $count -1]] products extras!

<p>

(Note: \"success\" doesn't actually mean that the information was uploaded; it
just means that Oracle didn't choke on it (since updates to tables are considered
successes even if 0 rows are updated).  If you need reassurance, spot check some of the individual products.)
[ad_admin_footer]
"


