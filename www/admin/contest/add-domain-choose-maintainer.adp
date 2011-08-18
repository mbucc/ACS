<%=[ad_admin_header "Choose Maintainer"]%>

<h2>Choose Maintainer</h2>

<%=[ad_admin_context_bar [list "index.tcl" "Contests"] "Choose Maintainer"]%>

<hr>

Some entry, confirmation, and error pages will need to be signed with
an email address.  This should be the name of the person who is the
maintainer of the contest or it might be a role, e.g., "Contest
Master".  

<p>

The maintainer may optionally choose to receive email notifications of
new contest entrants or, perhaps, daily summaries of contest activity.

<p>

In any case, it needs to be an already-registered user of
this community.

<p>

Look for a Maintainer by 

<blockquote>
<form method=GET action="/admin/users/search.tcl">
<input type=hidden name=target value="/admin/contest/add-domain-one-shot.adp">

<p>

Last Name: <input type=text name=last_name size=30>
<p>
or<p>
Email Address:  <input type=text name=email size=30>
</blockquote>
<center>
<input type=submit>

</center>

<%=[ad_admin_footer]%>

