# $Id: subcategory-update-2.tcl,v 3.0.4.1 2000/04/28 15:09:11 carsten Exp $
set_form_variables 

# subcategory_id, category_id
# and all the subcategory parameters

# user error checking

set exception_text ""
set exception_count 0

if { ![info exist subcategory_1] || [empty_string_p $subcategory_1] } {
    incr exception_count
    append exception_text "<li>Please entry a subcategory name."
}


if { [info exist decorative_photo] && [string length $decorative_photo] > 400 } {
    incr exception_count
    append exception_text "<li>Please limit the length of your custom HTML code to 400 characters."
}


if { [info exist publisher_hint] && [string length $publisher_hint] > 4000 } {
    incr exception_count
    append exception_text "<li>Please limit the top annotation to 4000 characters."
}

if { [info exist regional_p] && [string tolower $regional_p] != "t" && ![empty_string_p $region_type] } {
    incr exception_count
    append exception_text "<li>You selected a region type, but did not say \"Yes\" to group by region."
}

if { $exception_count > 0 } { 
  ad_return_complaint $exception_count $exception_text
  return
}

set db [ns_db gethandle]

# edit the form vars so we can use the magic insert/update
ns_set delkey [ns_conn form] submit


# Check the database to see if there is a row for this subcategory already.
# If there is a row, update the database with the information from the form.
# If there is no row, insert into the database with the information from the form.

if { [database_to_tcl_string $db "select count(subcategory_id) from n_to_n_subcategories where subcategory_id = $subcategory_id"] > 0 } {
    set sql_statement  [util_prepare_update $db n_to_n_subcategories subcategory_id $subcategory_id [ns_conn form]]
} else {
    set sql_statement  [util_prepare_insert $db n_to_n_subcategories subcategory_id $subcategory_id [ns_conn form]]
}

 
if [catch { ns_db dml $db $sql_statement } errmsg] {
	    ad_return_error "Failure to update subcategory  information" "The database rejected the attempt:
	    <blockquote>
<pre>
$errmsg
</pre>
</blockquote>
"
    return
}

ad_returnredirect "category.tcl?[export_url_vars category_id]"
