# /www/admin/gc/ads-from-one-category.tcl
ad_page_contract {
    Displays all the ads for one primary category within a domain for the adminstrator.

    @param domain_id which domain
    @param primary_category which primary category

    @author philg@mit.edu
    @cvs_id ads-from-one-category.tcl,v 3.4.2.5 2000/09/22 01:35:16 kevin Exp
} {
    domain_id:integer
    primary_category
}

db_1row domain_info "select domain, full_noun from ad_domains where domain_id = :domain_id"

set page_contents "[ad_admin_header "$primary_category Classified Ads"]

<h2>$primary_category Ads</h2>

[ad_admin_context_bar [list "index.tcl" "Classifieds"] [list "domain-top.tcl?domain_id=$domain_id" $full_noun] [list "manage-categories-for-domain.tcl?[export_url_vars domain_id]" "Categories"] "One Category"]

<hr>

<h3>$primary_category Ads</h3>

<ul>
"

set items ""

db_foreach ad_info {select classified_ad_id, one_line, primary_category, classified_ads.user_id, email as poster_email, posted, last_modified as edited_date, expired_p(expires) as expired_p, originating_ip, decode(last_modified, posted, 'f', 't') as ever_edited_p
from classified_ads, users
where users.user_id = classified_ads.user_id
and domain_id = :domain_id
and primary_category = :primary_category
order by classified_ad_id desc} {

    if { $originating_ip == "" } {
	set ip_stuff ""
    } else {
	set ip_stuff "(at 
<a href=\"ads-from-one-ip?domain_id=$domain_id&originating_ip=[ns_urlencode $originating_ip]\">$originating_ip</a>)"
    }
    if { $expired_p == "t" } {
	set expired_flag "<font color=red>expired</font>; "
    } else {
	set expired_flag ""
    }
    append items "<li>$classified_ad_id $primary_category:
$one_line<br>
(${expired_flag}submitted by
<a href=\"ads-from-one-user?[export_url_vars domain_id user_id]\">$poster_email</a> $ip_stuff $posted"
    if { $ever_edited_p == "t" } { 
	 append items "; edited $edited_date"
    }
    append items ")
\[<a  href=\"edit-ad?classified_ad_id=$classified_ad_id\">Edit</a> |
<a  href=\"delete-ad?classified_ad_id=$classified_ad_id\">Delete</a> \]
"

}

append page_contents $items

append page_contents "
</ul>

[ad_admin_footer]"


doc_return  200 text/html $page_contents
