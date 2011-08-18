# $Id: delete-ad-2.tcl,v 3.1.2.1 2000/04/28 15:10:34 carsten Exp $
set admin_id [ad_verify_and_get_user_id]
if { $admin_id == 0 } {
    ad_returnredirect "/register/"
    return
}

set_the_usual_form_variables

# classified_ad_id
# maybe user_charge (and if so, then perhaps charge_comment)

set db [ns_db gethandle]

if [catch { set selection [ns_db 1row $db "select ca.one_line, ca.full_ad, ca.domain_id, u.user_id, u.email, u.first_names, u.last_name, ad.domain
from classified_ads ca, ad_domains ad, users u
where ca.user_id = u.user_id
and ad.domain_id = ca.domain_id
and classified_ad_id = $classified_ad_id"] } errmsg ] {
    ad_return_error "Could not find Ad $classified_ad_id" "Either you are fooling around with the Location field in your browser
or my code has a serious bug.  The error message from the database was

<blockquote><code>
$errmsg
</blockquote></code>"
       return 
}
set_variables_after_query

if [catch { ns_db dml $db "begin transaction"
            ns_db dml $db [gc_audit_insert $classified_ad_id 1]
            ns_db dml $db "delete from classified_auction_bids where classified_ad_id = $classified_ad_id"
            ns_db dml $db "delete from classified_ads where classified_ad_id = $classified_ad_id"
            ns_db dml $db "end transaction" } errmsg] {
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
    mv_charge_user $db $user_charge "Deleting your ad from [ad_system_name]" "We had to delete your ad from [ad_system_name].

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

ns_db releasehandle $db
ns_return 200 text/html $html
