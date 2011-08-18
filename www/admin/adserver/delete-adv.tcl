# $Id: delete-adv.tcl,v 3.0 2000/02/06 02:46:09 ron Exp $
set_the_usual_form_variables

# adv_key

set db [ns_db gethandle]

set selection [ns_db 1row $db "select sum(display_count) as n_displays, sum(click_count) as n_clicks, min(entry_date) as first_display, max(entry_date) as last_display, round(max(entry_date)-min(entry_date)) as n_days, count(*) as n_entries
from adv_log 
where adv_key = '$QQadv_key'"]
set_variables_after_query

ns_return 200 text/html "[ad_admin_header "Confirm Deletion of $adv_key"]

<h2>Confirm Deletion</h2>

of <a href=\"one-adv.tcl?[export_url_vars adv_key]\">$adv_key</a>

<hr>

If what you want to do is stop showing an ad to users, you're in the
wrong place.  What you should be doing instead is changing the places
that reference this ad to reference some other ad.  Ads that have been
shown to users should never be deleted from the system because that
also deletes the logs.

<p>

Here's what you'll be deleting if you delete this ad:

<ul>
<li>$n_entries log entries 
<li>covering $n_days days (from $first_display to $last_display)
<li>during which there were $n_displays displays and $n_clicks clickthroughs 
</ul>

<p>

If you don't want to do that, then you can simply <a
href=\"index.tcl\">return to ad server administration</a>.



<p>

However, if you only put this ad in the database for a demonstration
or experiment and never actually showed it to any users, then you can 

<center>
<form method=GET action=\"delete-adv-2.tcl\">
[export_form_vars adv_key]
<input type=submit value=\"Confirm deletion of this ad and its log entries\">
</form>
</center>

[ad_admin_footer]
"
