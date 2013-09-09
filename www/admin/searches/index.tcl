# /www/admin/searches/index.tcl
ad_page_contract {
    @cvs-id  index.tcl,v 3.1.6.4 2000/09/22 01:36:05 kevin Exp
} {
}

set page_content "[ad_admin_header "User Searches"]

<h2>User Searches</h2>

[ad_admin_context_bar "User Searches"]

<hr>

<ul>
<li><form action=recent method=post>
last
<select name=num_days>
[ad_generic_optionlist [day_list] [day_list] 7]
</select> days <input type=submit name=submit value=\"Go\">
<li> <a href=\"word-list\">by word</a>
<li> <a href=\"location-list\">by location</a>
<li> <a href=\"results-none\">with 0 results</a>
<p>
</ul>

<h3>Expensive Queries (may take a long time) </h3>
<ul>
<li> <a href=\"by-word-aggregate\">by word</a> (summary report)
</ul>
[ad_admin_footer]
"

doc_return  200 text/html $page_content
