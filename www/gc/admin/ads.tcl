# /www/gc/admin/ads.tcl

ad_page_contract {
    will display all ads or some number of days worth 

    @author
    @creation-date
    @cvs-id ads.tcl,v 3.3.2.7 2000/09/22 01:37:58 kevin Exp

    @param domain_id integer
    @param num_days
} {
    domain_id:integer
    {num_days 7} 
}

db_1row gc_admin_ads_num_domains "select domain_id,
                            domain,
                            full_noun,
                            primary_maintainer_id,
                            domain_type,
                            blurb,
                            blurb_bottom,
                            insert_form_fragments,
                            ad_deletion_blurb,
                            default_expiration_days,
                            levels_of_categorization,
                            user_extensible_cats_p,
                            wtb_common_p,
                            auction_p,
                            geocentric_p,
                            active_p
                from ad_domains where domain_id = :domain_id"

if { ![info exists num_days] || [empty_string_p $num_days] || $num_days == "all" } {
    # all the ads 
    set description "All Ads"
    set day_limit_clause ""
} else {
    set day_limit_clause "\nand posted > (sysdate - :num_days)"
    if { $num_days == 1 } {
	set description "Ads from last 24 hours"
    } else {
	set description "Ads from last $num_days days"
    }
}

append html "[ad_admin_header "$domain Classified Ads"]

<h2>Classified Ads</h2>

[ad_context_bar_ws_or_index [list "/gc/" "Classifieds"] [list "index.tcl" "Classifieds Admin"] [list "domain-top.tcl?domain_id=$domain_id" $full_noun] $description]

<hr>

<h3>The Ads</h3>

<ul>
"

set sql "select classified_ad_id, 
                one_line, 
                primary_category,
                posted, 
                last_modified as edited_date, 
                originating_ip, 
                users.user_id, 
                email as poster_email, decode(last_modified, posted, 'f', 't') as ever_edited_p
from classified_ads, users 
where domain_id = :domain_id
and users.user_id = classified_ads.user_id
and (sysdate <= expires or expires is null) $day_limit_clause
order by classified_ad_id desc"

set items ""
db_foreach gc_admin_all_ad_list $sql {
    if { $originating_ip == "" } {
	set ip_stuff ""
    } else {
	set ip_stuff "(at 
<a href=\"ads-from-one-ip?domain_id=$domain_id&originating_ip=[ns_urlencode $originating_ip]\">$originating_ip</a>)"
    }
    append items "<li>$classified_ad_id $primary_category:
$one_line<br>
(from 
<a href=\"ads-from-one-user?[export_url_vars domain_id user_id]\">$poster_email</a> $ip_stuff on $posted"
     if { $ever_edited_p == "t" } { 
	 append items "; edited $edited_date"
     }
     append items ")
\[<a href=\"edit-ad?classified_ad_id=$classified_ad_id\">Edit</a> |
<a href=\"delete-ad?classified_ad_id=$classified_ad_id\">Delete</a> \]

"
}

append html $items
append html "
</ul>
[ad_admin_footer]
"


doc_return  200 text/html $html

