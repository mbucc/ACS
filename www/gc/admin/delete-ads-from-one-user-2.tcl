# $Id: delete-ads-from-one-user-2.tcl,v 3.1.2.2 2000/04/28 15:10:34 carsten Exp $
set admin_id [ad_verify_and_get_user_id]
if { $admin_id == 0 } {
    ad_returnredirect "/register/"
    return
}

set_the_usual_form_variables

# classified_ad_id, user_id, domain_id
# maybe user_charge (and if so, then perhaps charge_comment)

set db [ns_db gethandle]

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
where user_id = $user_id
and domain_id = $domain_id"

set delete_bids_sql "delete from classified_auction_bids
where classified_ad_id in
   (select classified_ad_id 
    from classified_ads
    where user_id = $user_id
    and domain_id = $domain_id)"

set delete_ads_sql "delete from classified_ads 
where user_id = $user_id
and domain_id = $domain_id"

if [catch { ns_db dml $db "begin transaction"
            ns_db dml $db $audit_sql
            ns_db dml $db $delete_bids_sql
            ns_db dml $db $delete_ads_sql 
            ns_db dml $db "end transaction" } errmsg] {
	# we shouldn't be able to get here except because of 
	# violating integrity constraints
	ad_return_error "Could not delete Ads from user $user_id" "I think my code must have a serious bug.
The error message from the database was

<blockquote><code>
$errmsg
</blockquote></code>"
        return
}

set domain [database_to_tcl_string $db "select domain from ad_domains
where domain_id = $domain_id"]

append html "[gc_header "Ads from User $user_id Deleted"]

<h2>Ads from User $user_id Deleted</h2>

in the <a href=\"domain-top.tcl?domain_id=$domain_id\"> $domain domain of [gc_system_name]</a>

<hr>

Deletion of ads confirmed.\n\n

"

if { [info exists user_charge] && ![empty_string_p $user_charge] } {
    if { [info exists charge_comment] && ![empty_string_p $charge_comment] } {
	# insert separately typed comment
	set user_charge [mv_user_charge_replace_comment $user_charge $charge_comment]
    }
    append html "<p> ... adding a user charge:
<blockquote>
[mv_describe_user_charge $user_charge]
</blockquote>
... "
    mv_charge_user $db $user_charge "Deleted your ads from [ad_system_name]" "We had to delete your ads from [ad_system_name].

Comment:  $charge_comment

(most likely you've violated the stated policy against screaming with
all-uppercase words or using other attention-getting characters in the
subject line).

Sorry for deleting all of your ads but that is really the only
possible way for a free site like this to stay afloat.  We can't
afford to pick through every ad so the easiest thing to do is just
click once and delete all the ads.
"
    append html "Done."
}

append html "

[ad_admin_footer]
"

ns_db releasehandle $db
ns_return 200 text/html $html
