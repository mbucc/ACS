# domain-administrator-update-2.tcl

ad_page_contract {
    @author
    @creation-date
    @cvs-id domain-administrator-update-2.tcl,v 3.2.6.4 2000/08/01 15:52:23 psu Exp

    @param domain_id
    @param user_id_from_search
    @param last_name_from_search
    @param email_from_search

} {
    domain_id:integer
    user_id_from_search
    first_names_from_search
    last_name_from_search
    email_from_search
}

db_dml gc_admin_domain_admin_update {
    update ad_domains set primary_maintainer_id = :user_id_from_search 
    where domain_id = :domain_id
}

db_release_unused_handles

ad_returnredirect "domain-top.tcl?[export_url_vars domain_id]"