# /admin/poll/votes-from-one-ip.tcl 

ad_page_contract {
    Shows the admin what has been happening from one IP address.

    @param poll_id the ID of the poll
    @param ip_address the IP address to lookup

    @author Philip Greenspun (philg@mit.edu)
    @creation-date October 25, 1999
    @cvs-id votes-from-one-ip.tcl,v 3.2.2.5 2000/09/22 01:35:49 kevin Exp
} {
    poll_id:notnull,naturalnum
    ip_address:notnull
}

db_1row get_poll_info "
select name, description, start_date, end_date, require_registration_p
  from polls
 where poll_id = :poll_id
"

set page_html "[ad_admin_header "Votes from $ip_address"]

<h2>Votes from $ip_address</h2>

[ad_admin_context_bar [list "/admin/poll" Polls] [list "one-poll?[export_url_vars poll_id]" "One"] [list "integrity-stats?[export_url_vars poll_id]" "Integrity Statistics"] "One IP Address"]

<hr>

These are votes from $ip_address in \"$name\".  First, let's try
translating the address to a hostname....  
"

with_catch errmsg {
    set hostname [ns_hostbyaddr $ip_address]
} {
    set hostname $ip_address
}

append page_html "$hostname

(if this is just the number again, that means the hostname could not
be found.)

<p>

<ul>

"

set items ""
db_foreach poll_choices_by_ip  "select 
  pc.label, 
  to_char(puc.choice_date,'YYYY-MM-DD HH24:MI:SS') as choice_time,
  puc.user_id,
  users.first_names,
  users.last_name
from poll_choices pc, poll_user_choices puc, users
where puc.user_id = users.user_id(+)
and pc.choice_id = puc.choice_id
and pc.poll_id = :poll_id
and puc.ip_address = :ip_address
order by puc.choice_date" {


    append items "<li>$choice_time:  $label"
    if [empty_string_p $user_id] {
	append items "--anonymous"
    } else {
	append items "--<a href=\"/admin/users/one?user_id=$user_id\">$first_names $last_name</a>"
    }
}

db_release_unused_handles

append page_html "$items

</ul>

[ad_admin_footer]
"

doc_return  200 text/html $page_html
