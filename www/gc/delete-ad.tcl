# delete-ad.tcl

ad_page_contract {
    @param classified_ad_id

    @cvs-id delete-ad.tcl,v 3.3.2.3 2000/09/22 01:37:52 kevin Exp
} {
    classified_ad_id:integer
}

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

if { [db_0or1row ads_check "select classified_ads.*
                            from classified_ads 
                            where classified_ad_id = :classified_ad_id" -bind [ad_tcl_vars_to_ns_set classified_ad_id]]==0 } {
    ad_return_error "Could not find Ad $classified_ad_id" "Could not find Ad $classified_ad_id.

<p>

Either you are fooling around with the Location field in your browser,
this ad is already delted,  or this code has a serious bug. "
     return 
}

# OK, we found the ad in the database if we are here...

db_1row domain_info_get [gc_query_for_domain_info $domain_id]

db_release_unused_handles

doc_return 200 text/html "[gc_header "Delete \"$one_line\""]

<h2>Delete \"$one_line\"</h2>

ad number $classified_ad_id in 
<a href=\"domain-top?[export_url_vars domain_id]\">$full_noun</a>

<hr>

Are you sure that you want to delete this ad?

<ul>
<li><a href=\"delete-ad-2?[export_url_vars classified_ad_id]\">yes, I'm sure</a>

<p>

<li><a href=\"edit-ad-2?[export_url_vars domain_id]\">no; let me look at my ads again</a>

</ul>

[gc_footer $maintainer_email]"

