# /admin/poll/integrity-stats.tcl


ad_page_contract {
    Try to get a handle on whether people are voting early and often

    @param poll_id the ID of the poll
   
    @author Philip Greenspun
    @creation-date 25 October 1999
    @cvs-id integrity-stats.tcl,v 3.3.2.7 2000/09/22 01:35:47 kevin Exp
} {
    poll_id:naturalnum,notnull
}

ad_maybe_redirect_for_registration

db_1row getpoll "
select name, description, start_date, end_date, require_registration_p
  from polls
 where poll_id = :poll_id"


append page_html "
[ad_admin_header "Integrity Statistics for $name"]

<h2>Integrity Statistics for $name</h2>

[ad_admin_context_bar [list "/admin/poll" Polls] [list "one-poll?[export_url_vars poll_id]" "One"] "Integrity Statistics"]

<hr>

This page tries to help you figure out if people are
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

db_foreach poll_integrity_subquery "select pc.label, puc.ip_address, count(*) as n_from_same_ip
from poll_choices pc, poll_user_choices puc
where pc.choice_id = puc.choice_id
and pc.poll_id = :poll_id
and user_id is not null
group by pc.label, puc.ip_address
having count(*) > 1
order by n_from_same_ip desc" {


    append page_html "<li>$label, <a href=\"votes-from-one-ip?[export_url_vars ip_address poll_id]\">$ip_address</a>:  $n_from_same_ip\n"
}

append page_html "
</ul>

Now let's have a look at anonymous duplicate votes from the same IP
address.

<ul>
"

db_foreach anonymous_votes "select 
  pc.label, 
  puc.ip_address, 
  count(*) as n_from_same_ip,
  round(24*(max(puc.choice_date) - min(puc.choice_date)),2) as n_hours_apart 
from poll_choices pc, poll_user_choices puc
where pc.choice_id = puc.choice_id
and pc.poll_id = :poll_id
and user_id is null
group by pc.label, puc.ip_address
having count(*) > 1
order by n_from_same_ip desc" {

    append page_html "<li>$label, <a href=\"votes-from-one-ip?[export_url_vars ip_address poll_id]\">$ip_address</a>:  $n_from_same_ip, $n_hours_apart hours apart\n"
}

db_release_unused_handles

append page_html "
</ul>

If you want to quickly eliminate the ballot-stuffers, you can set a
threshold of how many duplicate rows is too many and have the system
nuke them all:

<blockquote>
<form method=GET action=\"delete-anonymous-dupes\">
[export_form_vars poll_id]
Pick a threshold:  
<input type=text name=deletion_threshold size=4 value=3>
<input type=submit value=\"Nuke this many or more\">
</form>
</blockquote>

[ad_admin_footer]
"


doc_return  200 text/html $page_html




