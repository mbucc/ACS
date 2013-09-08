# /www/admin/gc/domain-delete-2.tcl
ad_page_contract {
    Lets the site administrator delete a domain.

    @param domain_id which domain

    @author philg@mit.edu
    @cvs_id domain-delete-2.tcl,v 3.1.10.4 2000/09/22 01:35:22 kevin Exp
} {
    domain_id:integer
}

set domain [db_string domain "select domain from ad_domains where domain_id = :domain_id"]

set n_ads [db_string n_ads "select count(*) from classified_ads where domain_id = :domain_id and (expires is null or expires > sysdate)"]

if { $n_ads > 50 } {
    ad_return_complaint 1 "<li>I'm sorry but we're not going to delete a domain with $n_ads live ads in it; you'll need to go into SQL*Plus and delete the ads yourself first."
    return
}

set admin_group_id [ad_administration_group_id "gc" $domain]

db_transaction {
if ![empty_string_p $admin_group_id] {
    db_dml user_group_map_queue_delete "delete from user_group_map_queue where group_id = :admin_group_id"
    db_dml user_group_map_delete "delete from user_group_map where group_id = :admin_group_id"
}

db_dml administration_info_delete "delete from administration_info where group_id = :admin_group_id"
db_dml user_groups_delete "delete from user_groups where group_id = :admin_group_id"
db_dml classified_email_alerts_delete "delete from classified_email_alerts where domain_id = :domain_id"
db_dml classified_auction_bids_delete "delete from classified_auction_bids
where classified_ad_id in (select classified_ad_id from classified_ads where domain_id = :domain_id)"
db_dml classified_ads_delete "delete from classified_ads where domain_id = :domain_id"
db_dml ad_categories_delete "delete from ad_categories where domain_id = :domain_id"
db_dml ad_integrity_checks_delete "delete from ad_integrity_checks where domain_id = :domain_id"
db_dml ad_domains_delete "delete from ad_domains where domain_id = :domain_id"
}

set page_content "[ad_admin_header "Deleted $domain"]

<h2>Deleted $domain</h2>

[ad_admin_context_bar [list "index.tcl" "Classifieds"] "Domain Deleted"]

<hr>

The $domain domain has been deleted.

[ad_admin_footer]
"


doc_return  200 text/html $page_content
