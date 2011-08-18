# $Id: ads-from-one-category.tcl,v 3.1 2000/03/10 23:58:47 curtisg Exp $
set_the_usual_form_variables

# domain_id, primary_category

set db [gc_db_gethandle]
set selection [ns_db 1row $db "select full_noun from ad_domains where domain_id = $domain_id"]
set_variables_after_query

append html "[ad_admin_header "$primary_category Classified Ads"]

<h2>$primary_category Ads</h2>

[ad_context_bar_ws_or_index [list "/gc/" "Classifieds"] [list "index.tcl" "Classifieds Admin"] [list "domain-top.tcl?domain_id=[ns_urlencode $domain_id]" $full_noun] [list "manage-categories-for-domain.tcl?[export_url_vars domain_id]" "Categories"] "One Category"]


<hr>

<h3>$primary_category Ads</h3>

<ul>
"

set selection [ns_db select $db "select classified_ad_id, one_line, primary_category, classified_ads.user_id, email as poster_email, posted, last_modified as edited_date, expired_p(expires) as expired_p, originating_ip, decode(last_modified, posted, 'f', 't') as ever_edited_p
from classified_ads, users
where users.user_id = classified_ads.user_id
and domain_id = $domain_id
and primary_category = '$QQprimary_category'
order by classified_ad_id desc"]

set items ""

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    if { $originating_ip == "" } {
	set ip_stuff ""
    } else {
	set ip_stuff "(at 
<a href=\"ads-from-one-ip.tcl?domain_id=[ns_urlencode $domain_id]&originating_ip=[ns_urlencode $originating_ip]\">$originating_ip</a>)"
    }
    if { $expired_p == "t" } {
	set expired_flag "<font color=red>expired</font>; "
    } else {
	set expired_flag ""
    }
    append items "<li>$classified_ad_id $primary_category:
$one_line<br>
(${expired_flag}submitted by
<a href=\"ads-from-one-user.tcl?[export_url_vars domain_id user_id]\">$poster_email</a> $ip_stuff $posted"
    if { $ever_edited_p == "t" } { 
	 append items "; edited $edited_date"
    }
    append items ")
\[<a target=another_window href=\"edit-ad.tcl?classified_ad_id=$classified_ad_id\">Edit</a> |
<a target=another_window href=\"delete-ad.tcl?classified_ad_id=$classified_ad_id\">Delete</a> \]
"

}

append html $items

append html "
</ul>

[ad_admin_footer]"

ns_db releasehandle $db
ns_return 200 text/html $html
