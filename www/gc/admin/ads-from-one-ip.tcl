# ads-from-one-ip.tcl

ad_page_contract {
    @author
    @creation-date
    @cvs-id ads-from-one-ip.tcl,v 3.3.2.7 2000/09/22 01:37:58 kevin Exp
    @param domain_id integer
    @param originating_ip 
} {
    domain_id:integer
    originating_ip
}

db_1row gc_admin_one_ip_domain_data_get "select * from ad_domains where domain_id = :domain_id"

append html "[ad_header "$domain Classified Ads"]
<h2>Classified Ads</h2>
from $originating_ip in <a href=\"domain-top?domain_id=$domain_id\">$domain</a>
<hr>
<h3>The Ads</h3>
<ul>
"

set sql {
    select classified_ad_id, one_line, primary_category, classified_ads.user_id, email as poster_email, 
           posted, last_modified as edited_date, expired_p(expires) as expired_p, 
           decode(last_modified, posted, 'f', 't') as ever_edited_p
    from classified_ads, users
    where users.user_id = classified_ads.user_id
    and domain_id = :domain_id
    and originating_ip = :originating_ip
    order by classified_ad_id desc
}

db_foreach gc_admin_one_ip_ad_list $sql {
    if { $expired_p == "t" } {
	set expired_flag "<font color=red>expired</font>; "
    } else {
	set expired_flag ""
    }
    append html "<li>$classified_ad_id $primary_category:
    $one_line<br>
    (${expired_flag}submitted by
    <a href=\"ads-from-one-user?[export_url_vars domain_id user_id]\">$poster_email</a> $posted"
     if { $ever_edited_p == "t" } { 
	 append html "; edited $edited_date"
     }
     append html ")
     \[<a  href=\"edit-ad?classified_ad_id=$classified_ad_id\">Edit</a> |
     <a  href=\"delete-ad?classified_ad_id=$classified_ad_id\">Delete</a> \]
     "

}

append html "
</ul>

Doing a reverse DNS now:  $originating_ip maps to ...  

"

set ok [catch {set host [ns_hostbyaddr $originating_ip]}]

if { $ok != 0 } {
    set host $originating_ip
}

append html "$host

<P>

(note: if you just get the number again, that means the hostname could
not be found.)

[ad_admin_footer]"


doc_return  200 text/html $html










