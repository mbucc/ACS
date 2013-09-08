# delete-ad-2.tcl
ad_page_contract {
    @author
    @creation-date
    @cvs-id delete-ad-2.tcl,v 3.3.2.7 2000/09/22 01:37:58 kevin Exp

    @param classified_ad_id
    @param user_charge
    @param charge_comment
} {
    classified_ad_id 
    {user_charge ""}
    {charge_comment ""}
}


set admin_id [ad_verify_and_get_user_id]
if { $admin_id == 0 } {
    ad_returnredirect "/register/"
    return
}



if {![db_0or1row gc_admin_ad_delete_get_info {
    select ca.one_line, ca.full_ad, ca.domain_id, u.user_id, u.email, u.first_names, u.last_name, ad.domain
    from classified_ads ca, ad_domains ad, users u
    where ca.user_id = u.user_id
    and ad.domain_id = ca.domain_id
    and classified_ad_id = :classified_ad_id}]
} {

    ad_return_error "Could not find Ad $classified_ad_id" "Either you are fooling around with the Location field in your browser
    or my code has a serious bug.
}


db_transaction {
    db_dml gc_admin_ad_delete_2_audit_insert [gc_audit_insert $classified_ad_id 1]
    db_dml gc_admin_ad_delete_2_delete_1 "delete from classified_auction_bids where classified_ad_id = :classified_ad_id"
    db_dml gc_ad_delete_2_delete_2 "delete from classified_ads where classified_ad_id = :classified_ad_id"
} on_error {
    # we shouldn't be able to get here except because of 
    # violating integrity constraints
    ad_return_error "Could not delete Ad $classified_ad_id" "I think my code must have a serious bug.
    The error message from the database was
    
    <blockquote><code>
    $errmsg
    </blockquote></code>"
    return
}

append html "[gc_header "Ad $classified_ad_id Deleted"]

<h2>Ad $classified_ad_id Deleted</h2>

[ad_context_bar_ws_or_index [list "/gc/" "Classifieds"] [list "index.tcl" "Classifieds Admin"] [list "domain-top.tcl?domain_id=$domain_id" $domain] "Ad Deleted"]

<hr>

Deletion of ad $classified_ad_id confirmed.\n\n

"

if { ![empty_string_p $user_charge] } {
    if { [info exists charge_comment] && ![empty_string_p $charge_comment] } {
	# insert separately typed comment
	set user_charge [mv_user_charge_replace_comment $user_charge $charge_comment]
    }
    append html "<p> ... adding a user charge:
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
    append html "Done."
}

append html "
[ad_admin_footer]
"

db_release_unused_handles
doc_return  200 text/html $html
