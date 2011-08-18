# $Id: category-update-2.tcl,v 3.0.4.1 2000/04/28 15:09:11 carsten Exp $
set_form_variables 

# category_id, submit
# regional_p, region_type, top_title, top_blurb,
#  noun_for_action, decorative_photo


# user error checking

set exception_text ""
set exception_count 0


if { ![info exist primary_category] || [empty_string_p $primary_category] } {
    incr exception_count
    append exception_text "<li>Please enter a category name."
}

if { ![info exist noun_for_about] || [empty_string_p $noun_for_about] } {
    incr exception_count
    append exception_text "<li>Please enter what users are posting about."
}

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

set db [ns_db gethandle]

# edit the form vars so we can use the magic update
ns_set delkey [ns_conn form] submit


# Check the database to see if there is a row for this category already.
# If there is a row, update the database with the information from the form.
# If there is no row, insert into the database with the information from the form.

set sql_statement  [util_prepare_update $db n_to_n_primary_categories category_id $category_id [ns_conn form]]
 
if [catch { ns_db dml $db $sql_statement } errmsg] {
	    ad_return_error "Failure to update category  information" "The database rejected the attempt:
	    <blockquote>
<pre>
$errmsg
</pre>
</blockquote>
"
    return
}

ad_returnredirect "category.tcl?[export_url_vars category_id]"