# $Id: votes-from-one-ip.tcl,v 3.0 2000/02/06 03:27:09 ron Exp $
# votes-from-one-ip.tcl 
#
# by philg@mit.edu on October 25, 1999
#
# shows the admin what has been happening from one IP address

set_the_usual_form_variables

# poll_id, ip_address

set db [ns_db gethandle]

set selection [ns_db 1row $db "
select name, description, start_date, end_date, require_registration_p
  from polls
 where poll_id = $poll_id
"]

set_variables_after_query

ReturnHeaders

ns_write "[ad_admin_header "Votes from $ip_address"]

<h2>Votes from $ip_address</h2>

[ad_admin_context_bar [list "/admin/poll" Polls] [list "one-poll.tcl?[export_url_vars poll_id]" "One"] [list "integrity-stats.tcl?[export_url_vars poll_id]" "Integrity Statistics"] "One IP Address"]

<hr>

These are votes from $ip_address in \"$name\".  First, let's try
translating the address to a hostname....  
"

with_catch errmsg {
    set hostname [ns_hostbyaddr $ip_address]
} {
    set hostname $ip_address
}

ns_write "$hostname

(if this is just the number again, that means the hostname could not
be found.)

<p>

<ul>

"

set selection [ns_db select $db "select 
  pc.label, 
  to_char(puc.choice_date,'YYYY-MM-DD HH24:MI:SS') as choice_time,
  puc.user_id,
  users.first_names,
  users.last_name
from poll_choices pc, poll_user_choices puc, users
where puc.user_id = users.user_id(+)
and pc.choice_id = puc.choice_id
and pc.poll_id = $poll_id
and puc.ip_address = '$ip_address'
order by puc.choice_date"]

set items ""

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append items "<li>$choice_time:  $label"
    if [empty_string_p $user_id] {
	append items "--anonymous"
    } else {
	append items "--<a href=\"/admin/users/one.tcl?user_id=$user_id\">$first_names $last_name</a>"
    }
}

ns_write "$items

</ul>

[ad_admin_footer]
"
