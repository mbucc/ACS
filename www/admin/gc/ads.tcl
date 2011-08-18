# $Id: ads.tcl,v 3.1 2000/03/11 00:45:10 curtisg Exp $
# will display all ads or some number of days worth 

set_the_usual_form_variables

# domain_id, optional num_days 

set db [gc_db_gethandle]
set selection [ns_db 1row $db "select * from ad_domains where domain_id = $domain_id"]
set_variables_after_query

if { ![info exists num_days] || [empty_string_p $num_days] || $num_days == "all" } {
    # all the ads 
    set description "All Ads"
    set day_limit_clause ""
} else {
    set day_limit_clause "\nand posted > (sysdate - $num_days)"
    if { $num_days == 1 } {
	set description "Ads from last 24 hours"
    } else {
	set description "Ads from last $num_days days"
    }
}


append html "[ad_admin_header "$domain Classified Ads"]

<h2>Classified Ads</h2>

[ad_admin_context_bar [list "index.tcl" "Classifieds"] [list "domain-top.tcl?domain_id=$domain_id" $full_noun] $description]


<hr>

<h3>The Ads</h3>

<ul>

"

set selection [ns_db select $db "select classified_ad_id, one_line, primary_category,posted, last_modified as edited_date, originating_ip, users.user_id, email as poster_email, decode(last_modified, posted, 'f', 't') as ever_edited_p
from classified_ads, users 
where domain_id = $domain_id
and users.user_id = classified_ads.user_id
and (sysdate <= expires or expires is null) $day_limit_clause
order by classified_ad_id desc"]

set items ""
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    if { $originating_ip == "" } {
	set ip_stuff ""
    } else {
	set ip_stuff "(at 
<a href=\"ads-from-one-ip.tcl?domain_id=$domain_id&originating_ip=[ns_urlencode $originating_ip]\">$originating_ip</a>)"
    }
    append items "<li>$classified_ad_id $primary_category:
$one_line<br>
(from 
<a href=\"ads-from-one-user.tcl?[export_url_vars domain_id user_id]\">$poster_email</a> $ip_stuff on $posted"
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

[ad_admin_footer]
"

ns_db releasehandle $db
ns_return 200 text/html $html
