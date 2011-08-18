# $Id: index.tcl,v 3.0 2000/02/06 03:24:43 ron Exp $
ReturnHeaders

ns_write "[ad_admin_header "Related Links"]

<h2>Related Links</h2>

[ad_admin_context_bar "Links"]


<hr>

<ul>
<li><form action=recent.tcl method=post>
added in the last
<select name=num_days>
[ad_generic_optionlist [day_list] [day_list] 7]
</select> days <input type=submit name=submit value=\"Go\">
</form>
<li><a href=\"by-page.tcl\">by page</a>
<li><a href=\"by-user.tcl\">by user</a>
<li><a href=\"recent.tcl?num_days=all\">all</a>
<p>

<form method=GET action=\"find.tcl\">
<li>Search by URL or title:  
<input type=text name=query_string size=30>
</form>

<p>
<li><a href=\"spam-hunter.tcl\">spam hunter</a>
<li><a href=\"blacklist-all.tcl\">view the anti-spam blacklist</a>
<p>
<li><a href=\"sweep.tcl?page_id=all\">sweep the entire database for dead links</a>
</ul>

"

set db [ns_db gethandle]

set selection [ns_db 1row $db "
select 
  count(*) as total,
  sum(decode(status,'live',1,0)) as n_live,
  sum(decode(status,'coma',1,0)) as n_coma,
  sum(decode(status,'dead',1,0)) as n_dead,
  sum(decode(status,'removed',1,0)) as n_removed
from links"]

set_variables_after_query

ns_write "
<h3>Statistics</h3>

<ul>
<li>total:  $total
<li>live:  $n_live
<li>coma: $n_coma
<li>dead: $n_dead
<li>removed: $n_removed
</ul>

[ad_admin_footer]
"
