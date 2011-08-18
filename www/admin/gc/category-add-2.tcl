# $Id: category-add-2.tcl,v 3.1.2.1 2000/04/28 15:09:01 carsten Exp $
# parameters

set_form_variables
set_form_variables_string_trim_DoubleAposQQ

# category_id, domain_id, primary_category, ad_placement_blurb

# user error checking

set exception_text ""
set exception_count 0

if { ![info exists primary_category] || [empty_string_p $primary_category] } {
    incr exception_count
    append exception_text "<li>Please enter a category name."
}

if { ![info exists ad_placement_blurb] || [string length ad_placement_blurb] > 4000 } {
    incr exception_count
    append exception_text "<li>Please limit you ad placement annotation to 4000 characters."
}


if { $exception_count > 0 } { 
  ad_return_complaint $exception_count $exception_text
  return
}


set db [gc_db_gethandle]


ns_db dml $db "insert into ad_categories 
    (category_id, primary_category, domain_id, ad_placement_blurb)
     values ($category_id, '$QQprimary_category' , $domain_id , '$QQad_placement_blurb')"

ad_returnredirect "manage-categories-for-domain.tcl?domain_id=$domain_id"


