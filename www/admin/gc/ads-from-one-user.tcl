# $Id: ads-from-one-user.tcl,v 3.1 2000/03/11 00:45:10 curtisg Exp $
set_the_usual_form_variables

# domain_id, user_id

set db [gc_db_gethandle]
set selection [ns_db 1row $db "select full_noun from ad_domains where domain_id = $domain_id"]
set_variables_after_query

set selection [ns_db 1row $db "select first_names, last_name, email 
from users
where user_id = $user_id"]
set_variables_after_query

append html "[ad_admin_header "Ads from $email"]

<h2>Ads from $email</h2>

[ad_admin_context_bar [list "index.tcl" "Classifieds"] [list "domain-top.tcl?domain_id=$domain_id" $full_noun] "One User"]

<hr>

<ul>
<li>user admin page: 
<a href=\"/admin/users/one.tcl?user_id=$user_id\">$first_names $last_name</a>

<li>email:  <a href=\"mailto:$email\">$email</a>


</ul>

<h3>The Ads</h3>

<ul>
"

set selection [ns_db select $db "select classified_ad_id, one_line, primary_category, posted, last_modified as edited_date, expired_p(expires) as expired_p, originating_ip, decode(last_modified, posted, 'f', 't') as ever_edited_p
from classified_ads, users
where users.user_id = classified_ads.user_id
and domain_id = $domain_id
and classified_ads.user_id = $user_id
order by classified_ad_id desc"]

set counter 0
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    incr counter
    if { [empty_string_p $originating_ip] } {
	set ip_stuff ""
    } else {
	set ip_stuff "at 
<a href=\"ads-from-one-ip.tcl?domain_id=$domain_id&originating_ip=[ns_urlencode $originating_ip]\">$originating_ip</a>"
    }

    if { $expired_p == "t" } {
	set expired_flag "<font color=red>expired</font>; "
    } else {
	set expired_flag ""
    }
    append html "<li>$classified_ad_id $primary_category:
$one_line<br>
($ip_stuff; $posted"
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

"

if { $counter != 0 } {
    append html "<p>
You can <a href=\"delete-ads-from-one-user.tcl?[export_url_vars domain_id user_id]\">delete all of the above ads</a>.
"
}

append html [ad_admin_footer]

ns_db releasehandle $db
ns_return 200 text/html $html
