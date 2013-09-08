# /www/admin/gc/edit-ad-2.tcl
ad_page_contract {
    Lets the site administrator edit a user's classified ad.

    @param user_charge what the user is charged for making a bad posting
    @param charge_comment the comment that goes along with the charge
    @param classified_ad_id which ad is being edited
    @param domain which classified ad domain

    @author philg@mit.edu
    @cvs_id edit-ad-2.tcl,v 3.4.2.4 2000/09/22 01:35:22 kevin Exp
} {
    {user_charge ""}
    {charge_comment ""}
    {classified_ad_id:integer}
    {domain_id:integer}
}

# Note: there are other variables being passed in, but there's no
# need to set them locally using ad_page_contract; they will just
# be inserted into the database using util_prepare_for_update and
# [ns_conn form].

set admin_id [ad_verify_and_get_user_id]

if { $admin_id == 0 } {
    ad_returnredirect "/register/"
    return
}

# Do not be worried by the fact that you are seeing the variables
# that were passed in being overwritten; the database will be
# updated using the values in [ns_conn form], whereas the variables
# that are now being set will be used for sending email to the 
# person who posted the classified ad (we want to tell them what
# their ad used to say).

if { ![db_0or1row ad_info "select * from classified_ads where classified_ad_id = :classified_ad_id"] } {

    ad_return_error "Could not find Ad $classified_ad_id" "Either you are fooling around with the Location field in your browser or my code has a serious bug."
    return    
}

# If we got here, that means that the ad is indeed a valid one, so
# go ahead and do the update.

set update_sql_and_bind_vars [util_prepare_update classified_ads classified_ad_id $classified_ad_id [ns_conn form]]
set update_sql [lindex $update_sql_and_bind_vars 0]
set bind_vars [lindex $update_sql_and_bind_vars 1]

if [catch { db_dml ad_update $update_sql -bind $bind_vars } errmsg] {
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
    set page_content "[gc_header "Success"]

<h2>Success!</h2>

updating ad number $classified_ad_id in the
 <a href=\"domain-top?domain_id=$domain_id\"> [db_string domain "select domain from ad_domains where domain_id = :domain_id"] domain of [gc_system_name]</a>

<hr>

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
    mv_charge_user $user_charge "Editing your ad in [ad_system_name]" "We had to edit your ad in [ad_system_name].

For clarity, here is what we had in the database..

Subject:  $one_line

Full Ad:

$full_ad
"
    append page_content "Done."
}

append page_content "

<p>

If you'd like to check the ad, then take a look 
at <a href=\"/gc/view-one?classified_ad_id=$classified_ad_id\">the public page</a>.

[ad_admin_footer]"
}


doc_return  200 text/html $page_content
