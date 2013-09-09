# /www/admin/neighbor/category-update-2.tcl
ad_page_contract {
    Updates a category.

    @author Philip Greenspun (philg@mit.edu)
    @creation-date 1 January 1996
    @cvs-id category-update-2.tcl,v 3.3.2.3 2000/07/21 03:57:42 ron Exp
    @param category_id the category to edit
    @param primary_category the category name
    @param noun_for_about an about noun
    @param regional_p whether to group by region
    @param region_type the region to group by
    @param top_title a title for the category page
    @param top_blurb a blurb about the category
    @param noun_for_action an about noun
    @param decorative_photo some HTML to place at the top of the category page
} {
    category_id:notnull,integer
    primary_category:notnull
    noun_for_about:notnull
    regional_p:optional
    region_type
    top_title
    top_blurb
    noun_for_action:optional
    decorative_photo:html
}

set exception_text ""
set exception_count 0

if { [info exist top_blurb] && [string length $top_blurb] > 4000 } {
    incr exception_count
    append exception_text "<li>Please limit the length of your category page annotation to 4000 characters."
}

if { [info exist decorative_photo] && [string length $decorative_photo] > 400 } {
    incr exception_count
    append exception_text "<li>Please limit the length of your custom HTML code to 400 characters."
}

if { [info exist pre_post_blurb] && [string length $pre_post_blurb] > 4000 } {
    incr exception_count
    append exception_text "<li>Please limit the length of your pre-posting annotation to 4000 characters."
}

if { [info exist regional_p] && [string tolower $regional_p] != "t" && ![empty_string_p $region_type] } {
    incr exception_count
    append exception_text "<li>You selected a region type, but did not say \"Yes\" to group by region."
}

if { $exception_count > 0 } { 
  ad_return_complaint $exception_count $exception_text
  return
}



# edit the form vars so we can use the magic update
ns_set delkey [ns_conn form] submit

# Check the database to see if there is a row for this category already.
# If there is a row, update the database with the information from the form.
# If there is no row, insert into the database with the information from the form.

set sql_statement_and_bind_vars [util_prepare_update n_to_n_primary_categories category_id $category_id [ns_conn form]]
set sql_statement [lindex $sql_statement_and_bind_vars 0]
set bind_vars [lindex $sql_statement_and_bind_vars 1]

if [catch { db_dml category_update $sql_statement -bind $bind_vars} errmsg] {
    db_release_unused_handles
    ad_return_error "Failure to update category  information" "The database rejected the attempt:
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