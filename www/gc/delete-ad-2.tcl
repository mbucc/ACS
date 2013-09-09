# /www/gc/delete-ad-2.tcl

ad_page_contract {
    @param classified_ad_id

    @cvs-id delete-ad-2.tcl,v 3.4.2.5 2000/09/22 01:37:52 kevin Exp
} {
    classified_ad_id:integer
}

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

if { [ad_get_user_id] == 0 } {
    ad_returnredirect /register/index.tcl?return_url=[ns_urlencode /gc/delete-ad-2.tcl?[export_url_vars classified_ad_id]]
}

if { [db_0or1row domain_list "
      select ca.user_id, ca.domain_id, ad_deletion_blurb, email as maintainer_email
      from classified_ads ca, ad_domains, users   
      where ca.domain_id = ad_domains.domain_id
      and classified_ad_id = :classified_ad_id
      and ad_domains.primary_maintainer_id = users.user_id" -bind [ad_tcl_vars_to_ns_set classified_ad_id]]==0 } {
	  ad_return_error "Could not find Ad $classified_ad_id" "Could not find this ad in <a href=index>[gc_system_name]</a>

<p>

Probably the ad was deleted already (maybe you double clicked?).

<p>

Start from <a href=\"/gc/\">the top level classifieds area</a> 
and then click down to review your ads to
see if this ad is still there.
"
       return 
}

if { $user_id != [ad_verify_and_get_user_id] } {
    ad_return_error "Unauthorized" "You are not authorized to edit this ad."
    return
}

db_transaction {
    db_dml prepare_delete [gc_audit_insert $classified_ad_id]
    db_dml bids_delete "delete from classified_auction_bids where classified_ad_id = :classified_ad_id" -bind [ad_tcl_vars_to_ns_set classified_ad_id]
    db_dml ads_delete  "delete from classified_ads where classified_ad_id = :classified_ad_id" -bind [ad_tcl_vars_to_ns_set classified_ad_id]
} on_error {
	# we shouldn't be able to get here except because of 
	# violating integrity constraints
	ad_return_error "Error Deleting Ad" "I think my code must have a serious bug.
The error message from the database was

<blockquote><code>
$errmsg
</blockquote></code>
[gc_footer $maintainer_email]"
        return
}

doc_return  200 text/html "[gc_header "Ad $classified_ad_id Deleted"]

<h2>Ad $classified_ad_id Deleted</h2>

from [ad_site_home_link]

<hr>

Deletion of ad $classified_ad_id confirmed.

<p>

$ad_deletion_blurb

<p>

You might want to <a href=\"edit-ad-2?[export_url_vars domain_id]\">review your remaining ads</a>.

[gc_footer $maintainer_email]
"
