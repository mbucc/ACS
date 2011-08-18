# $Id: delete-ad.tcl,v 3.1 2000/03/10 23:58:22 curtisg Exp $
if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set_the_usual_form_variables

# classified_ad_id

set db [gc_db_gethandle]
set selection [ns_db 0or1row $db "select 
classified_ads.*
from classified_ads
where classified_ad_id = $classified_ad_id"]

if { $selection == "" } {
    ad_return_error "Could not find Ad $classified_ad_id" "Could not find Ad $classified_ad_id.

<p>

Either you are fooling around with the Location field in your browser,
this ad is already delted,  or this code has a serious bug. "
     return 
}

# OK, we found the ad in the database if we are here...
set_variables_after_query

set selection [ns_db 1row $db [gc_query_for_domain_info $domain_id]]
set_variables_after_query

ReturnHeaders
ns_write "[gc_header "Delete \"$one_line\""]

<h2>Delete \"$one_line\"</h2>

ad number $classified_ad_id in 
<a href=\"domain-top.tcl?[export_url_vars domain_id]\">$full_noun</a>

<hr>

Are you sure that you want to delete this ad?

<ul>
<li><a href=\"delete-ad-2.tcl?[export_url_vars classified_ad_id]\">yes, I'm sure</a>

<p>

<li><a href=\"edit-ad-2.tcl?[export_url_vars domain_id]\">no; let me look at my ads again</a>

</ul>


[gc_footer $maintainer_email]"
