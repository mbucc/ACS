# /www/admin/gc/delete-category.tcl
ad_page_contract {
    Allows administrator to delete a primary category in a domain.

    @param domain_id which domain

    @author philg@mit.edu
    @cvs_id delete-category.tcl,v 3.2.6.4 2000/07/26 21:12:03 bryanche Exp
} {
    category_id:naturalnum,notnull
    domain_id:naturalnum,notnull
}

db_dml category_delete "delete from ad_categories 
where category_id=:category_id"

ad_returnredirect "manage-categories-for-domain.tcl?domain_id=$domain_id"
