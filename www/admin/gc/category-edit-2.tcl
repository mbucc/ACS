# $Id: category-edit-2.tcl,v 3.1.2.1 2000/04/28 15:09:01 carsten Exp $
#
# parameters

set_the_usual_form_variables

# domain_id, primary_category, old_primary_category, submit_type, ad_placement_blurb


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

if { [regexp -nocase {Edit} $submit_type] } {
    set new_category_value $QQprimary_category
} elseif { [regexp -nocase {convert} $submit_type] } {
    set new_category_value [string tolower $QQprimary_category]
} else {
    ns_return 200 text/html "couldn't figure out what to do"
    return
}

ns_db dml $db "begin transaction"
ns_db dml $db "update ad_categories 
set primary_category = '$new_category_value',
ad_placement_blurb = '$QQad_placement_blurb'
where domain_id = $domain_id and primary_category = '$QQold_primary_category'"
ns_db dml $db "update classified_ads
set primary_category = '$new_category_value'
where domain_id = $domain_id and primary_category = '$QQold_primary_category'"
ns_db dml $db "end transaction"

ad_returnredirect "manage-categories-for-domain.tcl?domain_id=$domain_id"

