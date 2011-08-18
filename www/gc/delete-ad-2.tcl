# $Id: delete-ad-2.tcl,v 3.1.2.1 2000/04/28 15:10:30 carsten Exp $
if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}


set_the_usual_form_variables

# classified_ad_id

if { [ad_get_user_id] == 0 } {
    ad_returnredirect /register/index.tcl?return_url=[ns_urlencode /gc/delete-ad-2.tcl?[export_url_vars classified_ad_id]]
}

set db [gc_db_gethandle]

set selection [ns_db 0or1row $db "select ca.user_id, ca.domain_id, ad_deletion_blurb, email as maintainer_email
from classified_ads ca, ad_domains, users
where ca.domain_id = ad_domains.domain_id
and classified_ad_id = $classified_ad_id
and ad_domains.primary_maintainer_id = users.user_id"]

if { $selection == "" } {
    ad_return_error "Could not find Ad $classified_ad_id" "Could not find this ad in <a href=index.tcl>[gc_system_name]</a>

<p>

Probably the ad was deleted already (maybe you double clicked?).

<p>

Start from <a href=\"/gc/\">the top level classifieds area</a> 
and then click down to review your ads to
see if this ad is still there.
"
       return 
}
set_variables_after_query

if { $user_id != [ad_verify_and_get_user_id] } {
    ad_return_error "Unauthorized" "You are not authorized to edit this ad."
    return
}


if [catch { ns_db dml $db "begin transaction"
            ns_db dml $db [gc_audit_insert $classified_ad_id]
            ns_db dml $db "delete from classified_auction_bids where classified_ad_id = $classified_ad_id"
            ns_db dml $db "delete from classified_ads where classified_ad_id = $classified_ad_id"
            ns_db dml $db "end transaction" } errmsg] {
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

ns_return 200 text/html "[gc_header "Ad $classified_ad_id Deleted"]

<h2>Ad $classified_ad_id Deleted</h2>

from [ad_site_home_link]

<hr>

Deletion of ad $classified_ad_id confirmed.

<p>

$ad_deletion_blurb

<p>

You might want to <a href=\"edit-ad-2.tcl?[export_url_vars domain_id]\">review your remaining ads</a>.

[gc_footer $maintainer_email]
"
