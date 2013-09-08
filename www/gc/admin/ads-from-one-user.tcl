# ads-from-one-user.tcl

ad_page_contract {
    @author
    @creation-date
    @cvs-id ads-from-one-user.tcl,v 3.3.2.7 2000/09/22 01:37:58 kevin Exp
    @param domain_id integer
    @param user_id integer
} {
    domain_id:integer
    user_id:integer
}

db_1row gc_admin_one_user_domain_data_get "select full_noun from ad_domains where domain_id = :domain_id"


db_1row gc_admin_one_user_name_get { 
    select first_names, last_name, email 
    from users
    where user_id = :user_id
}

append html "[ad_header "Ads from $email"]

<h2>Ads from $email</h2>

[ad_context_bar_ws_or_index [list "/gc/" "Classifieds"] [list "index.tcl" "Classifieds Admin"] [list "domain-top.tcl?domain_id=$domain_id" $full_noun] "One User"]

<hr>

<ul>
<li>user admin page: 
<a href=\"/admin/users/one?user_id=$user_id\">$first_names $last_name</a>

<li>email:  <a href=\"mailto:$email\">$email</a>

</ul>

<h3>The Ads</h3>

<ul>
"

set sql {
    select classified_ad_id, one_line, primary_category, posted, last_modified as edited_date,
           expired_p(expires) as expired_p, originating_ip, decode(last_modified, posted, 'f', 't') as ever_edited_p
    from classified_ads, users
    where users.user_id = classified_ads.user_id
    and domain_id = :domain_id
    and classified_ads.user_id = :user_id
    order by classified_ad_id desc
}

set counter 0
db_foreach gc_admin_one_user_ad_list $sql {    
    incr counter
    if { [empty_string_p $originating_ip] } {
	set ip_stuff ""
    } else {
	set ip_stuff "at 
	<a href=\"ads-from-one-ip?domain_id=[ns_urlencode $domain_id]&originating_ip=[ns_urlencode $originating_ip]\">$originating_ip</a>"
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
     \[<a href=\"edit-ad?classified_ad_id=$classified_ad_id\">Edit</a> |
     <a href=\"delete-ad?classified_ad_id=$classified_ad_id\">Delete</a> \]
     "

}

append html "
</ul>

"

if { $counter != 0 } {
    append html "<p>
You can <a href=\"delete-ads-from-one-user?[export_url_vars domain_id user_id]\">delete all of the above ads</a>.
"
}

append html [ad_admin_footer]


doc_return  200 text/html $html





