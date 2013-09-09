# /www/gc/edit-ad-3.tcl

ad_page_contract {
    @cvs_id edit-ad-3.tcl,v 3.4.2.5 2000/09/22 01:37:52 kevin Exp
} {
    classified_ad_id
}

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set auth_user_id [ad_verify_and_get_user_id]

if { $auth_user_id == 0 } {
    ad_returnredirect "/register/index.tcl?return_url=[ns_urlencode /gc/edit-ad-3.tcl?[export_url_vars classified_ad_id]]"
}

if { [db_0or1row ad_info_get "
select 
classified_ads.*
from classified_ads
where classified_ad_id = :classified_ad_id" -bind [ad_tcl_vars_to_ns_set classified_ad_id]]==0 } {
    ad_return_error "Could not find Ad $classified_ad_id" "Could not find Ad $classified_ad_id.

<p>

Either you are fooling around with the Location field in your browser,
the ad has been deleted, or this code has a serious bug."
       return 
}

# OK, we found the ad in the database if we are here...

db_1row domain_info_get [gc_query_for_domain_info $domain_id]

append html "[gc_header "Edit \"$one_line\""]

<h2>Edit \"$one_line\"</h2>

[ad_context_bar_ws_or_index [list "index.tcl" [gc_system_name]] [list "domain-top.tcl?[export_url_vars domain_id]" $full_noun] "Edit Ad #$classified_ad_id"]

<hr>

<p>

<h3>The Ad</h3>

<ul>
<li>One-line Summary:  $one_line

<p>

<li>What people see when they click on the above:
<blockquote>
[util_maybe_convert_to_html $full_ad $html_p]
</blockquote>

<li>Expires:  [util_AnsiDatetoPrettyDate $expires]

<li>Category: $primary_category
<p>"

# geocentric data

if { $geocentric_p == "t" } {

    if {$state != ""} {
	append html "<li>State:  [ad_state_name_from_usps_abbrev $state]<br>"
    }

    if {$country != ""} {
	append html "<li>Country:  [ad_country_name_from_country_code $country] <br>"
    }
    
}

append html "
</ul>

<form method=post action=edit-ad-4>

<input type=hidden name=classified_ad_id value=$classified_ad_id>

<h3>Actions</h3>

<ul>
<li><a href=\"edit-ad-4?[export_url_vars classified_ad_id]\">edit</a>

<p>

<li><a href=\"delete-ad?[export_url_vars classified_ad_id]\">delete</a>

</ul>

[gc_footer $maintainer_email]"

doc_return  200 text/html $html

