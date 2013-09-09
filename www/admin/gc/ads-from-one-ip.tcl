ad_page_contract {
    Displays all the ads for one IP address within a domain for the adminstrator.
    @param domain_id which domain
    @param originating_ip the IP address of the person who placed the ad

    @author philg@mit.edu
    @cvs_id ads-from-one-ip.tcl,v 3.3.2.6 2000/09/22 01:35:17 kevin Exp
} {
    domain_id:integer
    originating_ip
}


db_1row domain_info "select domain, full_noun from ad_domains where domain_id = :domain_id"

set page_contents "[ad_admin_header "$domain Classified Ads"]

<h2>Classified Ads</h2>

from $originating_ip in <a href=\"domain-top?domain_id=$domain_id]\">$domain</a>

<hr>

<h3>The Ads</h3>

<ul>
"

db_foreach ad_info {select classified_ad_id, one_line, primary_category, classified_ads.user_id, email as poster_email, posted, last_modified as edited_date, expired_p(expires) as expired_p, decode(last_modified, posted, 'f', 't') as ever_edited_p
from classified_ads, users
where users.user_id = classified_ads.user_id
and domain_id = :domain_id
and originating_ip = :originating_ip
order by classified_ad_id desc} {

    if { $expired_p == "t" } {
	set expired_flag "<font color=red>expired</font>; "
    } else {
	set expired_flag ""
    }
    append page_contents "<li>$classified_ad_id $primary_category:
$one_line<br>
(${expired_flag}submitted by
<a href=\"ads-from-one-user?[export_url_vars domain_id user_id]\">$poster_email</a> $posted"
     if { $ever_edited_p == "t" } { 
	 append page_contents "; edited $edited_date"
     }
     append page_contents ")
\[<a href=\"edit-ad?classified_ad_id=$classified_ad_id\">Edit</a> |
<a href=\"delete-ad?classified_ad_id=$classified_ad_id\">Delete</a> \]

"

}

append page_contents "
</ul>

Doing a reverse DNS now:  $originating_ip maps to ...  

"

if [catch {ns_hostbyaddr $originating_ip} originating_host] {
    append page_contents "$originating_ip"
} else {
    append page_contents "$originating_host"
}
append page_contents "

<P>

(note: if you just get the number again, that means the hostname could
not be found.)

[ad_admin_footer]"


doc_return  200 text/html $page_contents

