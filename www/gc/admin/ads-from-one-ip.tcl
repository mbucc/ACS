# $Id: ads-from-one-ip.tcl,v 3.1 2000/03/10 23:58:47 curtisg Exp $
set_form_variables
set_form_variables_string_trim_DoubleAposQQ

# domain_id, originating_ip

set db [gc_db_gethandle]
set selection [ns_db 1row $db "select * from ad_domains where domain_id = $domain_id"]
set_variables_after_query

append html "[ad_header "$domain Classified Ads"]

<h2>Classified Ads</h2>

from $originating_ip in <a href=\"domain-top.tcl?domain_id=$domain_id\">$domain</a>

<hr>

<h3>The Ads</h3>

<ul>
"

set selection [ns_db select $db "select classified_ad_id, one_line, primary_category, classified_ads.user_id, email as poster_email, posted, last_modified as edited_date, expired_p(expires) as expired_p, decode(last_modified, posted, 'f', 't') as ever_edited_p
from classified_ads, users
where users.user_id = classified_ads.user_id
and domain_id = $domain_id
and originating_ip = '$QQoriginating_ip'
order by classified_ad_id desc"]

while {[ns_db getrow $db $selection]} {

    set_variables_after_query
    if { $expired_p == "t" } {
	set expired_flag "<font color=red>expired</font>; "
    } else {
	set expired_flag ""
    }
    append html "<li>$classified_ad_id $primary_category:
$one_line<br>
(${expired_flag}submitted by
<a href=\"ads-from-one-user.tcl?[export_url_vars domain_id user_id]\">$poster_email</a> $posted"
     if { $ever_edited_p == "t" } { 
	 append html "; edited $edited_date"
     }
     append html ")
\[<a target=another_window href=\"edit-ad.tcl?classified_ad_id=$classified_ad_id\">Edit</a> |
<a target=another_window href=\"delete-ad.tcl?classified_ad_id=$classified_ad_id\">Delete</a> \]

"

}



append html "
</ul>


Doing a reverse DNS now:  $originating_ip maps to ...  

"

append html "[ns_hostbyaddr $originating_ip]

<P>

(note: if you just get the number again, that means the hostname could
not be found.)

[ad_admin_footer]"

ns_db releasehandle $db
ns_return 200 text/html $html
