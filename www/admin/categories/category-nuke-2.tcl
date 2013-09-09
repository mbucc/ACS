# /www/admin/categories/category-nuke-2.tcl
ad_page_contract {

  Actually nukes a category.

  @param category_id Category ID we're nuking

  @author sskracic@arsdigita.com
  @author michael@yoon.org 
  @creation-date October 31, 1999
  @cvs-id category-nuke-2.tcl,v 3.3.2.5 2000/07/23 16:47:22 seb Exp

} {

  category_id:naturalnum,notnull

}


if {[db_string children_count "
select count(child_category_id)
from category_hierarchy
where parent_category_id = :category_id" ] > 0} {
    ad_return_error "Problem nuking category" \
	"Cannot nuke category until all of its subcategories have been nuked."
    return
}

db_transaction {
    db_dml delete_users_interests "delete from users_interests where category_id = :category_id" 
    db_dml delete_category_hierarchy "delete from category_hierarchy where child_category_id = :category_id" 
    db_dml delete_category "delete from categories where category_id = :category_id" 

} on_error {
    ad_return_error "Problem nuking category" "$errmsg"
    return
}

db_release_unused_handles

ad_returnredirect "index"

