# /www/admin/neighbor/category-administrator-update-2.tcl
ad_page_contract {
    Changes the administrator of a category.

    @author Philip Greenspun (philg@mit.edu)
    @creation-date 1 January 1996
    @cvs-id category-administrator-update-2.tcl,v 3.2.2.2 2000/07/25 08:39:44 kevin Exp
    @param category_id the category whose administrator should be changed
    @param user_id_from_search the user ID of the new administrator
    @param first_names_from_search the new administrator's first names
    @param last_name_from_search the new administrator's last name
    @param email_from_search the new administrator's email
} {
    category_id:notnull,integer
    user_id_from_search:notnull,integer
    first_names_from_search
    last_name_from_search
    email_from_search
}

db_dml update_admin "
  update n_to_n_primary_categories 
     set primary_maintainer_id = :user_id_from_search 
   where category_id = :category_id"

db_release_unused_handles
ad_returnredirect "category?[export_url_vars category_id]"