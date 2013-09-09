# /www/admin/gc/delete-ad-2.tcl
ad_page_contract {
    Lets the site administrator delete a user's classified ad.

    @param classified_ad_id which classified ad
    @param user_charge what the user is charged for making a bad posting
    @param charge_comment the comment that goes along with the charge

    @author philg@mit.edu
    @cvs_id delete-ad-2.tcl,v 3.4.2.4 2000/09/22 01:35:19 kevin Exp
} {
    classified_ad_id:integer
    {user_charge ""}
    {charge_comment ""}
}

set admin_id [ad_verify_and_get_user_id]

if { $admin_id == 0 } {
    ad_returnredirect "/register/"
    return
}


if {![db_0or1row ad_info "select ca.one_line, ca.full_ad, ca.domain_id, ad.domain, u.user_id, u.email, u.first_names, u.last_name
from classified_ads ca, ad_domains ad, users u
where ca.user_id = u.user_id
and ad.domain_id = ca.domain_id
and classified_ad_id = :classified_ad_id"]} {

    ad_return_error "Could not find Ad $classified_ad_id" "Either you are fooling around with the Location field in your browser or my code has a serious bug. "
    return 
}


db_transaction {
    db_dml gc_audit_insert [gc_audit_insert $classified_ad_id 1]
    db_dml bids_delete "delete from classified_auction_bids where classified_ad_id = :classified_ad_id"
    db_dml ad_delete "delete from classified_ads where classified_ad_id = :classified_ad_id"
} on_error {
    # we shouldn't be able to get here except because of 
    # violating integrity constraints
    ad_return_error "Could not delete Ad $classified_ad_id" "I think my code must have a serious bug.  The error message from the database was

<blockquote><code>
$errmsg
</blockquote></code>"

    return
}

set page_content "[gc_header "Ad $classified_ad_id Deleted"]

<h2>Ad $classified_ad_id Deleted</h2>

 in the <a href=\"domain-top?domain_id=$domain_id\"> $domain domain of [gc_system_name]</a>
<hr>

Deletion of ad $classified_ad_id confirmed.\n\n

"

if { [info exists user_charge] && ![empty_string_p $user_charge] } {
    if { [info exists charge_comment] && ![empty_string_p $charge_comment] } {
	# insert separately typed comment
	set user_charge [mv_user_charge_replace_comment $user_charge $charge_comment]
    }
    append page_content "<p> ... adding a user charge:
<blockquote>
[mv_describe_user_charge $user_charge]
</blockquote>
... "
    mv_charge_user $user_charge "Deleting your ad from [ad_system_name]" "We had to delete your ad from [ad_system_name].

For clarity, here is what we had in the database..

Subject:  $one_line

Full Ad:

$full_ad
"
    append page_content "Done."
}

append page_content "

[ad_admin_footer]
"


doc_return  200 text/html $page_content
