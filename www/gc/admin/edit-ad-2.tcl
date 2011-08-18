# $Id: edit-ad-2.tcl,v 3.1 2000/03/10 23:58:50 curtisg Exp $
ad_maybe_redirect_for_registration

set admin_id [ad_get_user_id]

set_the_usual_form_variables

# bunch of stuff including classified_ad_id; maybe user_charge
# actually most of these will have gotten overwritten by 
# set_variables_after_query after the next query


set db [ns_db gethandle]

if [catch { set selection [ns_db 1row $db "select ca.*, ad.domain
from classified_ads ca, ad_domains ad
where ad.domain_id = ca.domain_id and
classified_ad_id = $classified_ad_id"] } errmsg ] {
    ad_return_error "Could not find Ad $classified_ad_id" "Either you are fooling around with the Location field in your browser
or my code has a serious bug.  The error message from the database was

<blockquote><code>
$errmsg
</blockquote></code>"
       return 
}

# OK, we found the ad in the database if we are here...
# the variable SELECTION holds the values from the db
set_variables_after_query

# now we know to what domain this ad belongs

if ![ad_administration_group_member $db "gc" $domain $admin_id] {
    ad_return_error "Unauthorized" "Unauthorized" 
    return
}

set update_sql [util_prepare_update $db classified_ads classified_ad_id $classified_ad_id [ns_conn form]]

if [catch { ns_db dml $db $update_sql } errmsg] {
    # something went a bit wrong
    set_variables_after_query
    ad_return_error "Error Updating Ad $classified_ad_id" "Tried the following SQL:

<pre>
$update_sql
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
    mv_charge_user $db $user_charge "Editing your ad in [ad_system_name]" "We had to edit your ad in [ad_system_name].

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
at <a href=\"/gc/view-one.tcl?classified_ad_id=$classified_ad_id\">the public page</a>.

[ad_admin_footer]"
}

ns_db releasehandle $b
ns_return 200 text/html $html
