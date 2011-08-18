# $Id: upload-2.tcl,v 3.0 2000/02/06 03:21:10 ron Exp $
set_the_usual_form_variables
# csv_file

if { ![info exists csv_file] } {
    ad_return_error "Missing CSV File" "You must input the name of the .csv file on your local hard drive."
    return
}

set user_id [ad_get_user_id]
set ip [ns_conn peeraddr]


ReturnHeaders

ns_write "[ad_admin_header "Uploading Products"]

<h2>Uploading Products</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Products"] "Uploading Products"]

<hr>

<blockquote>
"

set unix_file_name [ns_queryget csv_file.tmpfile]

set db [ns_db gethandle]

if { ![file readable $unix_file_name] } {
    ns_write "Cannot read file $unix_file_name"
    return
}

set csvfp [open $unix_file_name]

set count 0
set success_count 0
while { [ns_getcsv $csvfp elements] != -1 } {
    incr count
    if { $count == 1 } {
	# first time through, we grab the number of columns and their names
	set number_of_columns [llength $elements]
	set columns $elements
	# These 2 lines added 1999-08-08
	set product_id_column [lsearch -exact $columns "product_id"]
	set product_name_column [lsearch -exact $columns "product_name"]
    } else {
	# this line is a product

	# All this directory stuff added 1999-08-08
	# To be consistent with directory-creation that occurs when a
	# product is added, dirname will be the first four letters 
	# (lowercase) of the product_name followed by the product_id
	# (for uniqueness)
	regsub -all {[^a-zA-Z]} [lindex $elements $product_name_column] "" letters_in_product_name 
	set letters_in_product_name [string tolower $letters_in_product_name]
	if [catch {set dirname "[string range $letters_in_product_name 0 3][lindex $elements $product_id_column]"}] {
	    #maybe there aren't 4 letters in the product name
	    set dirname "$letters_in_product_name[lindex $elements $product_id_column]"
	}
	
	set columns_sql "insert into ec_products (creation_date, available_date, dirname, last_modified, last_modifying_user, modified_ip_address "
	set values_sql " values (sysdate, sysdate, '[DoubleApos $dirname]', sysdate, $user_id, '$ip' "
	for { set i 0 } { $i < $number_of_columns } { incr i } {
	    append columns_sql ", [lindex $columns $i]"
	    append values_sql ", '[DoubleApos [lindex $elements $i]]'"
	}
	set sql "$columns_sql ) $values_sql )"

	# we have to also write a row into ec_custom_product_field_values
	# for consistency with add*.tcl (added 1999-08-08)
	ns_db dml $db "begin transaction"
	
	if { [catch {ns_db dml $db $sql} errmsg] } {
	    ns_write "<font color=red>FAILURE!</font> SQL: $sql<br>\n"
	    ns_db dml $db "end transaction"
	} else {
	    incr success_count
	    if { [catch {ns_db dml $db "insert into ec_custom_product_field_values (product_id, last_modified, last_modifying_user, modified_ip_address) values ([lindex $elements $product_id_column], sysdate, '$user_id', '[DoubleApos [ns_conn peeraddr]]')" } errmsg] } {
		ns_write "<font color=red>FAILURE!</font> Insert into ec_custom_product_field_values failed for product_id=$product_id<br>\n"
	    }
	    ns_db dml $db "end transaction"

	    # Get the directory where dirname is stored
	    set subdirectory "[ad_parameter EcommerceDataDirectory ecommerce][ad_parameter ProductDataDirectory ecommerce][ec_product_file_directory [lindex $elements $product_id_column]]"
	    ec_assert_directory $subdirectory
	    
	    set full_dirname "$subdirectory/$dirname"
	    ec_assert_directory $full_dirname
	}
    }
}

if { $success_count == 1 } {
    set product_string "product"
} else {
    set product_string "products"
}

ns_write "</blockquote>

<p>Successfully loaded $success_count $product_string out of [ec_decode $count "0" "0" [expr $count -1]].

[ad_admin_footer]
"


