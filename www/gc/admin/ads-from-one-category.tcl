# ads-from-one-category.tcl

ad_page_contract {
    @author
    @creation-date
    @cvs-id ads-from-one-category.tcl,v 3.3.2.6 2000/09/22 01:37:57 kevin Exp
    @param domain_id integer
    @param primary_category 
} {
    domain_id:integer,notnull
    primary_category
}

db_1row gc_admin_one_cat_domain_name_get "select full_noun from ad_domains where domain_id = :domain_id"

append html "[ad_admin_header "$primary_category Classified Ads"]

<h2>$primary_category Ads</h2>

[ad_context_bar_ws_or_index [list "/gc/" "Classifieds"] [list "index.tcl" "Classifieds Admin"] [list "domain-top.tcl?domain_id=[ns_urlencode $domain_id]" $full_noun] [list "manage-categories-for-domain.tcl?[export_url_vars domain_id]" "Categories"] "One Category"]

<hr>

<h3>$primary_category Ads</h3>

<ul>
"

set sql {
    select classified_ad_id, one_line, primary_category, classified_ads.user_id, email as poster_email, 
           posted, last_modified as edited_date, expired_p(expires) as expired_p, originating_ip, 
           decode(last_modified, posted, 'f', 't') as ever_edited_p
    from classified_ads, users
    where users.user_id = classified_ads.user_id
    and domain_id = :domain_id
    and primary_category = :primary_category
    order by classified_ad_id desc
}

set items ""

db_foreach gc_admin_one_cat_ad_list $sql {    
    if { $originating_ip == "" } {
	set ip_stuff ""
    } else {
	set ip_stuff "(at 
<a href=\"ads-from-one-ip?domain_id=[ns_urlencode $domain_id]&originating_ip=[ns_urlencode $originating_ip]\">$originating_ip</a>)"
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

append html $items

append html "
</ul>

[ad_admin_footer]"


doc_return  200 text/html $html



