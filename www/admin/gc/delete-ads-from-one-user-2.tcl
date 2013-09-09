# /www/admin/gc/delete-ads-from-one-user-2.tcl
ad_page_contract {
    Allows administrator to delete all the ads for one user_id.

    @param domain_id which domain
    @param user_id the user_id of the person who placed the ad
    @param classified_ad_id which ad
    @param user_charge what the user is charged for making a bad posting
    @param charge_comment the comment that goes along with the charge

    @author philg@mit.edu
    @cvs_id delete-ads-from-one-user-2.tcl,v 3.4.2.4 2000/09/22 01:35:21 kevin Exp
} {
    classified_ad_id:integer
    domain_id:integer
    user_id:integer
    {user_charge ""}
    {charge_comment ""}
}

set admin_id [ad_verify_and_get_user_id]

if { $admin_id == 0 } {
    ad_returnredirect "/register/"
    return
}


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
  '[DoubleApos [ns_conn peeraddr]]',
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

    db_dml audit_insert $audit_sql
    db_dml bids_delete $delete_bids_sql
    db_dml ads_delete $delete_ads_sql 
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

set domain [db_string domain "select domain from ad_domains where domain_id = :domain_id"]

set page_content "[gc_header "Ads from User $user_id Deleted"]

<h2>Ads from User $user_id Deleted</h2>

in the <a href=\"domain-top?domain_id=$domain_id\"> $domain domain of [gc_system_name]</a>

<hr>

Deletion of ads confirmed.\n\n

"

if { ![empty_string_p $user_charge] } {
    if { ![empty_string_p $charge_comment] } {
	# insert separately typed comment
	set user_charge [mv_user_charge_replace_comment $user_charge $charge_comment]
    }
    append page_content "<p> ... adding a user charge:
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
    append page_content "Done."
}

append page_content "

[ad_admin_footer]
"


doc_return  200 text/html $page_content