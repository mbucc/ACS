# /admin/links/index.tcl

ad_page_contract {
    Index for administration of links.

    @author Original Author Unknown
    @creation-date Original Date Unknown
    @cvs-id index.tcl,v 3.2.2.5 2000/09/22 01:35:30 kevin Exp
} {
}

set page_content "[ad_admin_header "Related Links"]

<h2>Related Links</h2>

[ad_admin_context_bar "Links"]

<hr>

<ul>
<li><form action=recent method=post>
added in the last
<select name=num_days>
[ad_generic_optionlist [day_list] [day_list] 7]
</select> days <input type=submit name=submit value=\"Go\">
</form>
<li><a href=\"by-page\">by page</a>
<li><a href=\"by-user\">by user</a>
<li><a href=\"recent?num_days=all\">all</a>
<p>

<form method=GET action=\"find\">
<li>Search by URL or title:  
<input type=text name=query_string size=30>
</form>

<p>
<li><a href=\"spam-hunter\">spam hunter</a>
<li><a href=\"blacklist-all\">view the anti-spam blacklist</a>
<p>
<li><a href=\"sweep?page_id=all\">sweep the entire database for dead links</a>
</ul>

"



db_1row select_links "
select 
  count(*) as total,
  sum(decode(status,'live',1,0)) as n_live,
  sum(decode(status,'coma',1,0)) as n_coma,
  sum(decode(status,'dead',1,0)) as n_dead,
  sum(decode(status,'removed',1,0)) as n_removed
from links"

db_release_unused_handles

append page_content "
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

doc_return  200 text/html $page_content
