# /www/admin/categories/category-update.tcl
ad_page_contract {

  Updates the properties of an existing category.

  @param category_id           Id of category we're updating
  @param category              Category name
  @param category_description  Category description
  @param mailing_list_info     What kind of spam user should expect if subscr.
  @param profiling_weight      Category profiling weight
  @param enabled_p             Enabled as User Interest category
  @param category_type         Dimension of categorization
  @param new_category_type     New type can be specified

  @author sskracic@arsdigita.com
  @author michael@yoon.org 
  @creation-date October 31, 1999
  @cvs-id category-update.tcl,v 3.4.2.7 2000/07/23 16:47:22 seb Exp
} {

  category_id:naturalnum,notnull
  category:notnull
  category_description
  mailing_list_info
  profiling_weight:naturalnum,notnull
  enabled_p:notnull
  category_type
  new_category_type

}

set exception_count 0
set exception_text ""

if {![info exists category] || [empty_string_p $category]} {
    incr exception_count
    append exception_text "<li>Please enter category name"
}

if {[info exists new_category_type] && ![empty_string_p $new_category_type]} {
    set category_type $new_category_type
}

if {[info exists category_description] && [string length $category_description] > 4000} {
    incr exception_count
    append exception_text "<li>Please limit your category description to 4000 characters"
}

if {[info exists mailing_list_info] && [string length $mailing_list_info] > 4000} {
    incr exception_count
    append exception_text "<li>Please limit your Mailing list information to 4000 characters"
}

set naughty_html_text [ad_check_for_naughty_html "$category $category_description $mailing_list_info $category_type $new_category_type"]

if { ![empty_string_p $naughty_html_text] } {
    append exception_text "<li>$naughty_html_text"
    incr exception_count
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text 
    return
}


db_dml update_category_properties "
UPDATE categories
SET category = :category,
category_type = :category_type,
category_description = :category_description,
mailing_list_info = :mailing_list_info,
enabled_p = :enabled_p,
profiling_weight = :profiling_weight
WHERE category_id = :category_id" 

db_release_unused_handles

ad_returnredirect "one?[export_url_vars category_id]"








