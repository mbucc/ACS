# delete-ads-from-one-user-2.tcl

ad_page_contract {
    @author
    @creation-date
    @cvs-id delete-ads-from-one-user-2.tcl,v 3.5.2.10 2000/09/22 01:37:59 kevin Exp

    @param user_id
    @param user_charge
    @param charge_comment

} {
    user_id:integer
    domain_id:integer
    {user_charge ""}
    {charge_comment ""}
}

set admin_id [ad_maybe_redirect_for_registration]

set peeraddr [ns_conn peeraddr]
set audit_sql "insert into classified_ads_audit 
 (classified_ad_id,
  user_id,
  domain_id,
  originating_ip,
  posted,
  expires,
  wanted_p,
  private_p,
  primary_category,
  subcategory_1,
  subcategory_2,
  manufacturer,
  model,
  one_line,
  full_ad,
  html_p,
  last_modified,
  audit_ip,
  deleted_by_admin_p)
select 
  classified_ad_id,
  user_id,
  domain_id,
  originating_ip,
  posted,
  expires,
  wanted_p,
  private_p,
  primary_category,
  subcategory_1,
  subcategory_2,
  manufacturer,
  model,
  one_line,
  full_ad,
  html_p,
  last_modified,
  :peeraddr,
  't'
from classified_ads 
where user_id = :user_id
and domain_id = :domain_id"

set delete_bids_sql "delete from classified_auction_bids
where classified_ad_id in
   (select classified_ad_id 
    from classified_ads
    where user_id = :user_id
    and domain_id = :domain_id)"

set delete_ads_sql "delete from classified_ads 
where user_id = :user_id
and domain_id = :domain_id"

db_transaction {
    db_dml gc_admin_del_one_user_audit $audit_sql
    db_dml gc_admin_del_one_user_bids_delete $delete_bids_sql
    db_dml gc_admin_del_one_user_ads_delete $delete_ads_sql 
} on_error {
    # we shouldn't be able to get here except because of 
    # violating integrity constraints
    ad_return_error "Could not delete ads from user $user_id" "I think my code must have a serious bug.
    The error message from the database was
    <blockquote><code>
    $errmsg
    </blockquote></code>"
    return
}


append doc_body "[gc_header "Ads from User $user_id Deleted"]

<h2>Ads from User $user_id Deleted</h2>
in the <a href=\"domain-top.tcl?domain=[ns_urlencode $domain_id]\"> $domain_id domain of [gc_system_name]</a>
<hr>
Deletion of ads confirmed.\n\n
"

if { [info exists user_charge] && ![empty_string_p $user_charge] } {
    if { [info exists charge_comment] && ![empty_string_p $charge_comment] } {
	# insert separately typed comment
	set user_charge [mv_user_charge_replace_comment $user_charge $charge_comment]
    }
    append doc_body "<p> ... adding a user charge:
<blockquote>
[mv_describe_user_charge $user_charge]
</blockquote>
... "
    mv_charge_user $user_charge "Deleted your ads from [ad_system_name]" "We had to delete your ads from [ad_system_name].

Comment:  $charge_comment

(most likely you've violated the stated policy against screaming with
all-uppercase words or using other attention-getting characters in the
subject line).

Sorry for deleting all of your ads but that is really the only
possible way for a free site like this to stay afloat.  We can't
afford to pick through every ad so the easiest thing to do is just
click once and delete all the ads.
"
    append doc_body "Done."
}

append doc_body "

[ad_admin_footer]
"

doc_return  200 text/html $doc_body













