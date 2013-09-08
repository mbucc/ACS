ad_page_contract {
    
    Display as much as we can know about activity from a particular IP address.
    @author Philip Greenspun [philg@mit.edu]
    @creation-date March 1, 1999
    @cvs-id host.tcl,v 3.2.2.3 2000/09/22 01:34:15 kevin Exp
} {
    ip
}

set page_content ""

append page_content "[ad_admin_header $ip]

<h2>$ip</h2>

[ad_admin_context_bar "One Host"]

<hr>

The first thing we'll do is try to look up the ip address ... 

"

set hostname [ns_hostbyaddr $ip]

append page_content "$hostname.

(If it is just the number again, that means the reverse DNS lookup failed.)
"

set items ""
db_foreach all_users_from_ip {
    select user_id, first_names, last_name, email 
    from users
    where registration_ip = :ip
} {
    append items "<li><a href=\"/admin/users/one?[export_url_vars user_id]\">$first_names $last_name</a> ($email)\n"
} 

if { ![empty_string_p $items] } {
    append page_content "<h3>User Registrations from $hostname</h3>

<ul>
$items
</ul>
"
}

set items ""
db_foreach all_msg_by_ip {
    select msg_id, one_line 
    from bboard 
    where originating_ip = :ip
} {
    append items "<li>$one_line\n"
}

if ![empty_string_p $items] {
    append page_content "<h3>BBoard postings from $hostname</h3>

<ul>
$items
</ul>

"
}

append page_content [ad_admin_footer]

doc_return 200 text/html $page_content