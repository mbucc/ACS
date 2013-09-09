# admin/neighbor/subcategory-update-2.tcl
ad_page_contract {
    @author unkown (3.4 by tnight@arsdigita.com)
    @creation-date 2000-07-17
    @cvs-di subcategory-update-2.tcl,v 3.3.2.4 2001/01/11 19:36:59 khy Exp
} {
    subcategory_id:integer,notnull,verify
    category_id:integer
    subcategory_1:notnull
    {decorative_photo:html,optional}
    {publisher_hint:optional}
    regional_p
    region_type
}

# subcategory-update-2.tcl,v 3.3.2.4 2001/01/11 19:36:59 khy Exp



set exception_text ""
set exception_count 0

#if { ![info exist subcategory_1] || [empty_string_p $subcategory_1] } {
#    incr exception_count
#    append exception_text "<li>Please entry a subcategory name."
#}

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


# edit the form vars so we can use the magic insert/update
ns_set delkey [ns_conn form] submit

# Check the database to see if there is a row for this subcategory already.
# If there is a row, update the database with the information from the form.
# If there is no row, insert into the database with the information from the form.

if { [db_string unused "select count(subcategory_id) from n_to_n_subcategories where subcategory_id = $subcategory_id"] > 0 } {
    set statement_name "subcategory_update"
    set sql_statement_and_bind_vars [util_prepare_update n_to_n_subcategories subcategory_id $subcategory_id [ns_conn form]]
} else {
    set statement_name "subcategory_insert"
    set form_data [ns_conn form]
    ns_set delkey $form_data "subcategory_id:sig"
    set sql_statement_and_bind_vars [util_prepare_insert n_to_n_subcategories $form_data]
}

set sql_statement [lindex $sql_statement_and_bind_vars 0]
set bind_vars [lindex $sql_statement_and_bind_vars 1]

if [catch { db_dml $statement_name $sql_statement -bind $bind_vars} errmsg] {
	    ad_return_error "Failure to update subcategory  information" "The database rejected the attempt:
	    <blockquote>
<pre>
$errmsg
</pre>
</blockquote>
"
    return
}

db_release_unused_handles

ad_returnredirect "category?[export_url_vars category_id]"


