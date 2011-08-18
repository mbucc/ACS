# $Id: manage-domain.tcl,v 3.1.2.1 2000/03/17 23:37:45 tzumainn Exp $
set_the_usual_form_variables

# domain_id

set db [ns_db gethandle]

set update_form_raw "<form method=post action=\"update-domain.tcl\">
[export_form_vars domain_id]
<table>
<tr><th>Contest Pretty Name<td><input type=text name=pretty_name size=40>
<tr><th>Home URL<td><input type=text name=home_url size=40>
<tr><th>Blather<br>(arbitrary HTML for the top of the page)<td><textarea name=blather rows=10 cols=50></textarea>
<tr><td>Notify maintainer when a user enters this contest?<td>
<input type=radio name=notify_of_additions_p value=t CHECKED> Yes
<input type=radio name=notify_of_additions_p value=f> No
<tr><td>Open only to residents of the United States?<td>
<input type=radio name=us_only_p value=t> Yes
<input type=radio name=us_only_p value=f> No
<tr><td colspan=2 align=center>-- the fields below only matter for our generated entry form; if you are using a static .html form on your own server then these switches don't change anything --
</table>
<p>
<input type=submit value=Submit>
</form>
"

set selection [ns_db 1row $db "select unique * from contest_domains where domain_id='$QQdomain_id'"]

set_variables_after_query
set final_form [bt_mergepiece $update_form_raw $selection]

ReturnHeaders

ns_write "[ad_admin_header "Manage $domain"]

<h2>Manage $domain ($pretty_name)</h2>

[ad_admin_context_bar [list "index.tcl" "Contests"] "Manage Contest"]

<hr>

<ul>
<li>automatically generated entry form: <a href=\"/contest/entry-form.tcl?[export_url_vars domain_id]\">/contest/entry-form.tcl?[export_url_vars domain_id]</a>

<li>target for a static form should be 
<a href=\"/contest/process-entry.tcl?[export_url_vars domain_id]\">/contest/process-entry.tcl?[export_url_vars domain_id]</a>



</ul>

<h3>Entrants</h3>


<ul>
<li>View the entrants: 
<a href=\"view-verbose.tcl?[export_url_vars domain_id]&order_by=email\">ordered by email address</a> |
<a href=\"view-verbose.tcl?[export_url_vars domain_id]&order_by=entry_date\">ordered by entry_date</a>


</ul>

<h3>Pick Winner(s)</h3>

<form method=post action=pick-winners.tcl>
<input type=hidden name=domain value=\"$domain\">
[export_form_vars domain_id]

How many winners:  <input name=n_winners type=text size=13>

<p>

Start Date:  [philg_dateentrywidget_default_to_today from_date] 

<p>

End Date:  [philg_dateentrywidget_default_to_today to_date] 

<p> 

(note: dates are inclusive, so 1995-11-01 and 1995-11-14 gets all
those who entered between midnight on the 1st of November and until
11:59 pm on the 14th)

<p>

<center>

<input type=submit value=\"Submit\">

</center>

</form>

<h3>Customize Your Contest</h3>

You don't have to limit yourself to collecting basic name, address,
and demographic information from each entrant.  You can define extra
columns to record whatever information people are willing to give you.

<P>

Suppose that you're a software publisher.  You would probably want to
know what kinds of computer are used by readers of your Web site.  You
can start a contest and then customize it to record
\"desktop_operating_system\" along with the standard stuff.  If you
let this server generate your entry form, users will be able to type
anything they want into this field.  If you run the entry form off
your own server, then you are free to code whatever HTML you like.
You can use an HTML SELECT to limit entrants' choices to Macintosh,
OS/2, Unix, Windows 95, or Windows NT.

<p>

These data that you collect will be reported along with the standard
columns in all the reports from this site.

<p>

If you're sold on this approach, then <a
href=\"add-custom-column.tcl?[export_url_vars domain_id]\">go ahead and start customizing</a>.

<h3>Basic Contest Parameters</h3>

$final_form

<p>

[ad_contest_admin_footer]
"

