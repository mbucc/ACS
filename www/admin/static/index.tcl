# $Id: index.tcl,v 3.0 2000/02/06 03:30:22 ron Exp $
ReturnHeaders

ns_write "[ad_admin_header "Static Content"]

<h2>Static Content</h2>

[ad_admin_context_bar "Static Content"]


<hr>

<form method=GET action=\"search.tcl\">
Search through titles, URLs:  
<input type=text name=query_string size=30>
</form>

<ul>

<li><a href=\"static-pages.tcl\">all pages in [ad_system_name]</a>

<li><a href=\"/admin/comments/by-page.tcl?only_unanswered_questions_p=1\">pages that are raising questions</a>

<P>

<li>page view report:  <a href=\"static-usage.tcl?order_by=url\">by URL</a> | <a href=\"static-usage.tcl?order_by=page_views\">by number of views</a>
<li><a href=\"/admin/comments/by-page.tcl\">page comment report</a>
<li><a href=\"/admin/links/by-page.tcl\">related link report</a>

<p>

<li><a href=\"link-check.tcl\">check links embedded in your static HTML files</a> (this is a spider program that will run over all the content in your server's file system)

<p>

<li><a href=\"static-syncer-ns-set.tcl\">sync database with file system</a>
</ul>

<h3>Index Exclusion</h3>

You can exclude some or all of the static pages from the index by
entering patterns that match the URL or page title of a static page.

<ul>

"

set db [ns_db gethandle]
set selection [ns_db select $db "select * 
from static_page_index_exclusion
order by upper(pattern)"]

set items ""
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append items "<li><a href=\"exclusion/one-pattern.tcl?[export_url_vars exclusion_pattern_id]\"><code>$pattern</code></a>\n"
}


ns_write "$items

<p>

<li><a href=\"exclusion/add.tcl\">Add a pattern</a>

<p>

<li><a href=\"exclusion/exclude.tcl\">Run all patterns</a>


</ul>

"




set selection [ns_db 1row $db "select 
  to_char(count(*),'999G999G999G999G999') as n_pages,
  to_char(sum(decode(index_p,'t',1,0)),'999G999G999G999G999') as n_indexed_pages,
  to_char(sum(dbms_lob.getlength(page_body)),'999G999G999G999G999') as n_bytes
from static_pages"]
set_variables_after_query

ns_write " 

<h3>Statistics</h3>

<ul>
<li>number of pages:  $n_pages ($n_indexed_pages to be indexed)
<li>total bytes:  $n_bytes

</ul>

A static page is one that sits in the file system, e.g.,
\"foobar.html\".  This is by way of contrast with content that is pulled
from the relational database, e.g.,
\"/bboard/q-and-a-fetch-msg.tcl?msg_id=000OQP\".  Static pages are fast
and reliable.  Static pages are editable with all kinds of standard
tools.  The main problem with static pages is that the RDBMS doesn't know 
when a static page has been added to the site.  Until you sync the database
with the file system, you won't be able to collect comments, links, etc. on 
the new page.

[ad_admin_footer]
"
