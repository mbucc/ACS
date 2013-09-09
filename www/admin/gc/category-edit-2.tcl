# /www/admin/gc/category-edit-2.tcl
ad_page_contract {
    Allows administrator to edit a category.

    @param domain_id which domain
    @param primary_category 
    @param old_primary_category former value of primary_category
    @param submit_type either Edit or convert
    @param ad_placement_blurb annotation for the ad placement page

    @author philg@mit.edu
    @cvs category-edit-2.tcl,v 3.3.2.5 2000/09/22 01:35:17 kevin Exp
} {
    domain_id:integer
    primary_category:trim,notnull
    old_primary_category
    submit_type:notnull
    ad_placement_blurb:trim
}

# user error checking

set exception_text ""
set exception_count 0

if { [empty_string_p $primary_category] } {
    incr exception_count
    append exception_text "<li>Please enter a category name."
}

if { [string length ad_placement_blurb] > 4000 } {
    incr exception_count
    append exception_text "<li>Please limit you ad placement annotation to 4000 characters."
}

if { $exception_count > 0 } { 
  ad_return_complaint $exception_count $exception_text
  return
}


if { [regexp -nocase {Edit} $submit_type] } {
    set new_category_value $primary_category
} elseif { [regexp -nocase {convert} $submit_type] } {
    set new_category_value [string tolower $primary_category]
} else {
    doc_return  200 text/html "couldn't figure out what to do"
    return
}

db_transaction {
    db_dml category_update "update ad_categories 
    set primary_category = :new_category_value,
    ad_placement_blurb = :ad_placement_blurb
    where domain_id = :domain_id
    and primary_category = :old_primary_category"

    db_dml ads_update "update classified_ads
    set primary_category = :new_category_value
    where domain_id = :domain_id
    and primary_category = :old_primary_category"
}

ad_returnredirect "manage-categories-for-domain.tcl?domain_id=$domain_id"

