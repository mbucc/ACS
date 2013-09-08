# /www/admin/gc/ads-from-one-user.tcl
ad_page_contract {
    Displays all the ads for one user_id within a domain for the adminstrator.

    @param domain_id which domain
    @param user_id the user_id of the person who placed the ad

    @author philg@mit.edu
    @cvs_id ads-from-one-user.tcl,v 3.3.2.5 2000/09/22 01:35:17 kevin Exp
} {
    domain_id:integer
    user_id:integer
}


db_1row domain_info "select full_noun from ad_domains where domain_id = :domain_id"

db_1row user_info "select first_names, last_name, email from users where user_id = :user_id"

set page_content "[ad_admin_header "Ads from $email"]

<h2>Ads from $email</h2>

[ad_admin_context_bar [list "index.tcl" "Classifieds"] [list "domain-top.tcl?domain_id=$domain_id" $full_noun] "One User"]

<hr>

<ul>
<li>user admin page: 
<a href=\"/admin/users/one?user_id=$user_id\">$first_names $last_name</a>

<li>email:  <a href=\"mailto:$email\">$email</a>

</ul>

<h3>The Ads</h3>

<ul>
"

set counter 0

db_foreach ad_info {select classified_ad_id, one_line, primary_category, posted, last_modified as edited_date, expired_p(expires) as expired_p, originating_ip, decode(last_modified, posted, 'f', 't') as ever_edited_p
from classified_ads, users
where users.user_id = classified_ads.user_id
and domain_id = :domain_id
and classified_ads.user_id = :user_id
order by classified_ad_id desc} {

    incr counter
    if { [empty_string_p $originating_ip] } {
	set ip_stuff ""
    } else {
	set ip_stuff "at 
<a href=\"ads-from-one-ip?domain_id=$domain_id&originating_ip=[ns_urlencode $originating_ip]\">$originating_ip</a>"
    }

    if { $expired_p == "t" } {
	set expired_flag "<font color=red>expired</font>; "
    } else {
	set expired_flag ""
    }
    append page_content "<li>$classified_ad_id $primary_category:
$one_line<br>
($ip_stuff; $posted"
     if { $ever_edited_p == "t" } { 
	 append page_content "; edited $edited_date"
     }
     append page_content ")
\[<a  href=\"edit-ad?classified_ad_id=$classified_ad_id\">Edit</a> |
<a  href=\"delete-ad?classified_ad_id=$classified_ad_id\">Delete</a> \]
"

}

append page_content "
</ul>

"

if { $counter != 0 } {
    append page_content "<p>
You can <a href=\"delete-ads-from-one-user?[export_url_vars domain_id user_id]\">delete all of the above ads</a>.
"
}

append page_content [ad_admin_footer]


doc_return  200 text/html $page_content
