# $Id: categories-upload-2.tcl,v 3.0 2000/02/06 03:19:47 ron Exp $
set_form_variables 0
# maybe csv_file

if { ![info exists csv_file] } {
    ad_return_error "Missing CSV File" "You must input the name of the .csv file on your local hard drive."
    return
}

set user_id [ad_get_user_id]
set ip [ns_conn peeraddr]

ReturnHeaders

ns_write "[ad_admin_header "Uploading Category Mappings"]

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Products"] "Uploading Categories"]

<hr>

<h3>Uploading Category Mappings</h3>

<blockquote>
"

set csv_file_name [ns_queryget csv_file.tmpfile]

set db [ns_db gethandle]
set db_sub [ns_db gethandle subquery]

set csvfp [open $csv_file_name]

set count 0
set success_count 0
while { [ns_getcsv $csvfp elements] != -1 } {
    incr count
    # this line is a product
    set product_id [lindex $elements 0]
    set category [DoubleApos [lindex $elements 1]]

    # see if this matches any subcategories
    set sql "select c.category_id, c.category_name, s.subcategory_id, s.subcategory_name from ec_subcategories s, ec_categories c where c.category_id = s.category_id and upper('$category') like upper(subcategory_name) || '%'"
    set selection [ns_db select $db $sql]
    set submatch_p 0
    while { [ns_db getrow $db $selection] } {
	set submatch_p 1
	set_variables_after_query
	# add this product to the matched subcategory
	set sql "insert into ec_subcategory_product_map (product_id, subcategory_id, publisher_favorite_p, last_modified, last_modifying_user, modified_ip_address) values ($product_id, $subcategory_id, 'f', sysdate, $user_id, '$ip')"
	if { [catch {ns_db dml $db_sub $sql} errmsg] } {
	    #error, probably already loaded this one
	} else {
	    ns_write "Matched $category to subcategory $subcategory_name in category $category_name<br>\n"
	}
	# now add it to the category that owns this subcategory
	set sql "insert into ec_category_product_map (product_id, category_id, publisher_favorite_p, last_modified, last_modifying_user, modified_ip_address) values ($product_id, $category_id, 'f', sysdate, $user_id, '$ip')"
	if { [catch {ns_db dml $db_sub $sql} errmsg] } {
	    #error, probably already loaded this one
	}
    }

    # see if this matches any categories
    set sql "select category_id, category_name from ec_categories where upper('$category') like upper(category_name) || '%'"
    set selection [ns_db select $db $sql]
    set match_p 0
    while { [ns_db getrow $db $selection] } {
	set match_p 1
	set_variables_after_query
	set sql "insert into ec_category_product_map (product_id, category_id, publisher_favorite_p, last_modified, last_modifying_user, modified_ip_address) values ($product_id, $category_id, 'f', sysdate, $user_id, '$ip')"
	if { [catch {ns_db dml $db_sub $sql} errmsg] } {
	    #error, probably already loaded this one
	} else {
	    ns_write "Matched $category to category $category_name<br>\n"
	}
    }
    if { ! ($match_p || $submatch_p) } {
	ns_write "<font color=red>Could not find matching category or subcategory for $category</font><br>\n"
    } else {
	incr success_count
    }
}

if { $success_count == 1 } {
    set category_string "category mapping"
} else {
    set category_string "category mappings"
}

ns_write "<p>Done loading $success_count $category_string out of $count.

</blockquote>

[ad_admin_footer]
"


