# /www/gc/admin/edit-ad-2.tcl

ad_page_contract {
    @author
    @creation-date
    @cvs-id edit-ad-2.tcl,v 3.2.6.8 2000/09/22 01:38:00 kevin Exp

    @param classified_ad_id
    @param state
    @param country
    @param one_line
    @param full_add
    @param html_p
    @param expires
    @param primary_category
    @param manufacturer
    @param model
    @param item_size
    @param color
    @param us_citizen_p
    @param wanted_p
    @param auction_p
    @param user_charge
    @param charge_comment

} {
    classified_ad_id
    {state ""}
    {country ""}
    one_line
    full_ad
    html_p
    expires
    primary_category
    {manufacturer ""}
    {model ""}
    {item_size ""}
    {color ""}
    {us_citizen_p ""}
    {wanted_p ""}
    {auction_p ""}    
    {user_charge ""}
    {charge_comment ""}
}

ad_maybe_redirect_for_registration

set admin_id [ad_get_user_id]

# bunch of stuff including classified_ad_id; maybe user_charge
# actually most of these will have gotten overwritten
# after the next query


if [catch { db_1row gc_admin_edit_ad_2_ad_data_get "
select ad.domain, ad.domain_id
from classified_ads ca, ad_domains ad
where ad.domain_id = ca.domain_id and
classified_ad_id = :classified_ad_id" } errmsg ] {
    ad_return_error "Could not find Ad $classified_ad_id" "Either you are fooling around with the Location field in your browser
    or my code has a serious bug.  The error message from the database was

    <blockquote><code>
    $errmsg
    </blockquote></code>"
    return
}

if {![ad_administrator_p] && ![ad_administration_group_member "gc" $domain $admin_id]} {
    ad_return_error "Unauthorized" "Unauthorized" 
    return
}

set sql_statement_and_bind_vars [util_prepare_update classified_ads classified_ad_id $classified_ad_id [ns_conn form]]
set sql_statement [lindex $sql_statement_and_bind_vars 0]
set bind_vars [lindex $sql_statement_and_bind_vars 1]

if [catch { db_dml gc_admin_edit_ad_2_update $sql_statement } errmsg] {
    # something went a bit wrong
    
    ad_return_error "Error Updating Ad $classified_ad_id" "Tried the following SQL:

    <pre>
    $sql_statement
    </pre>

    and got back the following:
    
    <blockquote><code>
    $errmsg
    </blockquote></code>"
    return
    
} else {

    # everything went nicely 
    append html "[gc_header "Success"]

<h2>Success!</h2>

[ad_context_bar_ws_or_index [list "/gc/" "Classifieds"] [list "index.tcl" "Classifieds Admin"] [list "domain-top.tcl?domain_id=$domain_id" $domain] "Edit Ad #$classified_ad_id"]

<hr>

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
    mv_charge_user $user_charge "Editing your ad in [ad_system_name]" "We had to edit your ad in [ad_system_name].

For clarity, here is what we had in the database..

Subject:  $one_line

Full Ad:

$full_ad
"
    append html "Done."
}


append html "

<p>

If you'd like to check the ad, then take a look 
at <a href=\"/gc/view-one?classified_ad_id=$classified_ad_id\">the public page</a>.

[ad_admin_footer]"
}

db_release_unused_handles
doc_return  200 text/html $html
