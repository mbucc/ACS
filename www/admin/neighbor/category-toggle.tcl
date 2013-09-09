# /www/admin/neighbor/category-toggle.tcl
ad_page_contract {
    toggles whether a category is active or not

    @author Philip Greenspun (philg@mit.edu)
    @creation-date 1 January 1996
    @cvs-id category-toggle.tcl,v 3.2.2.2 2000/07/25 08:39:44 kevin Exp
    @param category_id the category to change
} {
    category_id:notnull,integer
}


db_dml update_category "
  update n_to_n_primary_categories
     set active_p = logical_negation(active_p) 
   where category_id = :category_id"

db_release_unused_handles
ad_returnredirect ""

