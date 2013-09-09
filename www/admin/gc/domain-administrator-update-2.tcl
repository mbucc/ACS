# /www/admin/gc/domain-administrator-update-2.tcl
ad_page_contract {
    @param domain_id which domain
    @param user_id_from_search the user_id that comes from /user-search
    @param first_names_from_search the first_names that comes from /user-search
    @param last_name_from_search the last_name that comes from /user-search
    @param email_from_search the email address that comes from /user-search

    @author philg@mit.edu
    @cvs_id domain-administrator-update-2.tcl,v 3.2.6.3 2000/07/21 03:57:18 ron Exp

} {
    domain_id:integer
    user_id_from_search:integer
    first_names_from_search
    last_name_from_search
    email_from_search
}

db_dml maintainer_update "update ad_domains set primary_maintainer_id = :user_id_from_search where domain_id = :domain_id"

ad_returnredirect "domain-top.tcl?[export_url_vars domain_id]"

