<% 

set_form_variables 

# user_id_from_search is the one we care about

set db [ns_db gethandle]
set domain_id [database_to_tcl_string $db "select contest_domain_id_sequence.nextval from dual"]
ns_db releasehandle $db
  
%>

<%=[ad_header "Add New Contest"]%>

<h2>Add New Contest</h2>

<%=[ad_admin_context_bar [list "index.tcl" "Contests"] "New Contest"]%>

<hr>

<form method=post action="add-domain-one-shot-2.tcl">
<input type=hidden name=maintainer value=<%=$user_id_from_search%>>
<%= [export_form_vars domain_id] %>

<h3>About your Contest</h3>

We need something to use as a database key.  Something reasonably
short and without spaces, but descriptive.  E.g., for a contest where
you are giving away tickets to Paris, you could use "ParisTix" or
"Paris_tickets".

<p>

Your domain name is going to be part of a SQL table definition.  That
means that special characters such as "-" are out.  Just use
alphanumerics and underscores.  Oracle limits table names to 30
characters and we're already using 17 some to form the entrants table, so
please limit you domain name to no more than 13 characters.

<p>


Domain Name:  <input type=text name=domain size=12>

<p>

You don't want to show something ugly like "Paris_tickets" to
readers.  So please enter a pretty name, e.g., "Tickets to Paris
Contest".

<P>

Pretty Name:  <input type=text name=pretty_name size=30>

<p>

Next, we need to know the part of this service where the contest
starts off (typically one page before the entry form).  Presumably
this is on this server and need not include the "http://hostname"


<p>

Contest Home URL:  <input type=text name=home_url size=40 value="">

<p>

<%

if [ad_parameter SomeAmericanReadersP] {
    ns_puts "
Is your contest limited to residents of the United States?
<input type=radio name=us_only_p value=t> Yes
<input type=radio name=us_only_p value=f CHECKED> No
"
} else {
    ns_puts "<input type=hidden name=us_only_p value=f>\n"
}
%>

<p>

If we're going to generate an entry form for you, then you'll want to
explain something about this contest on the top level page, e.g.,
stating the conditions under which you are giving out prizes and what
people must do to win.  Note that, at least in the United States, it
is very difficult to run games of skill (where you give prizes only to
people who answer correctly).  It is much easier legally to run games
of chance (where you give prizes to everyone who enters).  An example
would be "Every month, we'll give away a free round-trip ticket to
Paris from any city in the United States.".

<p>

Explanatory HTML for the entry form:<br>

<textarea name=blather rows=10 cols=50>
</textarea>

<p>

<i>Note that this is unnecessary if you're going to write your own
entry form from scratch.</i>

<h3>Dates</h3>

This software will bounce entrants who are too early or too late.  You
just have to say when this contest starts and ends.

<p>

Contest Start Date (optional):  <%=[philg_dateentrywidget_default_to_today start_date]%>

<br>
Contest End Date (optional):  <%=[philg_dateentrywidget_default_to_today end_date]%>


<h3>Options</h3>

You can change these later, so don't agonize too much... 

<p>

Do you want the maintainer to be notified every time a user enters the
contest?

<input type=radio name=notify_of_additions_p value=t> Yes
<input type=radio name=notify_of_additions_p value=f CHECKED> No

<p>

<i>Note: you might set this up to notify you right now, then disable it
once you have a good feel for the volume of entries.</i>

<p>


<center>
<input type=submit value="Enter This New Contest in the Database">
</center>

</form>

<%=[ad_contest_admin_footer]%>
