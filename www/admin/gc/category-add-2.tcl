# /www/admin/gc/category-add-2.tcl
ad_page_contract {
    Allows administrator to add a category.

    @param domain_id which domain
    @param category_id the ID of this category
    @param category_name the name of this category
    @param ad_placcement_blurb annotation for the ad placement page

    @author philg@mit.edu
    @cvs category-add-2.tcl,v 3.3.2.4 2001/01/10 18:56:45 khy Exp
} {
    category_id:integer,notnull,verify
    domain_id:integer
    primary_category:trim,notnull
    ad_placement_blurb:trim
}


# user error checking

set exception_text ""
set exception_count 0

if { [string length ad_placement_blurb] > 4000 } {
    incr exception_count
    append exception_text "<li>Please limit you ad placement annotation to 4000 characters."
}

if { $exception_count > 0 } { 
  ad_return_complaint $exception_count $exception_text
  return
}

#double-click protectection
set dbl_clk [db_string gc_cat_dbl_clk "select count(*)
from ad_categories where category_id=:category_id"]
if {$dbl_clk > 0} {
    ad_return_warning "Category Alreaded Exists" "A category with
    this ID already exists.  Perhaps you double-clicked?"
    return
}


db_dml category_add "insert into ad_categories 
    (category_id, primary_category, domain_id, ad_placement_blurb)
     values (:category_id, :primary_category, :domain_id, :ad_placement_blurb)"

ad_returnredirect "manage-categories-for-domain.tcl?domain_id=$domain_id"

