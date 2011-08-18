# $Id: integrity-stats.tcl,v 3.0 2000/02/06 03:26:58 ron Exp $
# integrity-stats.tcl
#
# try to get a handle on whether people are voting early and often

# by philg@mit.edu on October 25, 1999

set_form_variables

# expects poll_id

ad_maybe_redirect_for_registration

set db [ns_db gethandle]

set selection [ns_db 1row $db "
select name, description, start_date, end_date, require_registration_p
  from polls
 where poll_id = $poll_id
"]

set_variables_after_query

ReturnHeaders

ns_write "
[ad_admin_header "Integrity Statistics for $name"]

<h2>Integrity Statistics for $name</h2>

[ad_admin_context_bar [list "/admin/poll" Polls] [list "one-poll.tcl?[export_url_vars poll_id]" "One"] "Integrity Statistics"]

<hr>

This page tries to help you figure out if people are people are
stuffing the ballot box in \"$name\".  This is particularly important
for polls that don't require registration.

<p>

First, let's have a look at votes from the same IP address where the
user ID is not null.  Presumably these are genuinely distinct people
since the poll software won't accept votes from the same person twice.
This should give you an idea of how likely it is that your users are
coming through proxies, etc.:

<ul>
"

set selection [ns_db select $db "select pc.label, puc.ip_address, count(*) as n_from_same_ip
from poll_choices pc, poll_user_choices puc
where pc.choice_id = puc.choice_id
and pc.poll_id = $poll_id
and user_id is not null
group by pc.label, puc.ip_address
having count(*) > 1
order by n_from_same_ip desc"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    ns_write "<li>$label, <a href=\"votes-from-one-ip.tcl?[export_url_vars ip_address poll_id]\">$ip_address</a>:  $n_from_same_ip\n"
}


ns_write "
</ul>

Now let's have a look at anonymous duplicate votes from the same IP
address.

<ul>
"

set selection [ns_db select $db "select 
  pc.label, 
  puc.ip_address, 
  count(*) as n_from_same_ip,
  round(24*(max(puc.choice_date) - min(puc.choice_date)),2) as n_hours_apart 
from poll_choices pc, poll_user_choices puc
where pc.choice_id = puc.choice_id
and pc.poll_id = $poll_id
and user_id is null
group by pc.label, puc.ip_address
having count(*) > 1
order by n_from_same_ip desc"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    ns_write "<li>$label, <a href=\"votes-from-one-ip.tcl?[export_url_vars ip_address poll_id]\">$ip_address</a>:  $n_from_same_ip, $n_hours_apart hours apart\n"
}

ns_write "
</ul>

If you want to quickly eliminate the ballot-stuffers, you can set a
threshold of how many duplicate rows is too many and have the system
nuke them all:

<blockquote>
<form method=GET action=\"delete-anonymous-dupes.tcl\">
[export_form_vars poll_id]
Pick a threshold:  
<input type=text name=deletion_threshold size=4 value=3>
<input type=submit value=\"Nuke this many or more\">
</form>
</blockquote>

[ad_admin_footer]
"

