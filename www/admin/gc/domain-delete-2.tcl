# $Id: domain-delete-2.tcl,v 3.1 2000/03/11 00:45:12 curtisg Exp $
set_the_usual_form_variables

# domain_id

set db [ns_db gethandle]

set domain [database_to_tcl_string $db "select domain
from ad_domains where domain_id = $domain_id"]

set n_ads [database_to_tcl_string $db "select count(*) 
from classified_ads 
where domain_id = $domain_id
and (expires is null or expires > sysdate)"]

if { $n_ads > 50 } {
    ad_return_complaint 1 "<li>I'm sorry but we're not going to delete a domain with $n_ads live ads in it; you'll need to go into SQL*Plus and delete the ads yourself first."
    return
}

set admin_group_id [ad_administration_group_id $db "gc" $domain]

ns_db dml $db "begin transaction"
if ![empty_string_p $admin_group_id] {
    ns_db dml $db "delete from user_group_map_queue where group_id = $admin_group_id"
    ns_db dml $db "delete from user_group_map where group_id = $admin_group_id"
}
ns_db dml $db "delete from administration_info where group_id = $admin_group_id"
ns_db dml $db "delete from user_groups where group_id = $admin_group_id"
ns_db dml $db "delete from classified_email_alerts where domain_id = $domain_id"
ns_db dml $db "delete from classified_auction_bids
where classified_ad_id in (select classified_ad_id from classified_ads where domain_id = $domain_id)"
ns_db dml $db "delete from classified_ads where domain_id = $domain_id"
ns_db dml $db "delete from ad_categories where domain_id = $domain_id"
ns_db dml $db "delete from ad_integrity_checks where domain_id = $domain_id"
ns_db dml $db "delete from ad_domains where domain_id = $domain_id"
ns_db dml $db "end transaction"

append html "[ad_admin_header "Deleted $domain"]

<h2>Deleted $domain</h2>

[ad_admin_context_bar [list "index.tcl" "Classifieds"] "Domain Deleted"]

<hr>

The $domain domain has been deleted.

[ad_admin_footer]
"

ns_db releasehandle $db
ns_return 200 text/html $html
