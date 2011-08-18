# $Id: search.tcl,v 3.0 2000/02/06 03:30:26 ron Exp $
set_the_usual_form_variables 0

# query_string, optional order_by 

if { ![info exists order_by] || [empty_string_p $order_by] || $order_by == "url" } {
    set option "order by <a href=\"static-pages.tcl?order_by=title\">title</a>"
    set order_by_clause "url_stub, upper(rtrim(ltrim(page_title)))"
} elseif { $order_by == "title" } {
    set option "order by <a href=\"static-pages.tcl?order_by=url\">URL</a>"
    set order_by_clause "upper(rtrim(ltrim(page_title))), url_stub"
}

ReturnHeaders

ns_write "[ad_admin_header "Static Pages matching \"$query_string\""]

<h2>Static Pages matching \"$query_string\"</h2>

[ad_admin_context_bar [list "index.tcl" "Static Content"] "Search Results"]


<hr>

$option

<ul>
"

set db [ns_db gethandle]

set selection [ns_db select $db "select page_id, rtrim(ltrim(page_title,' \n'),' \n') as page_title, url_stub
from static_pages
where draft_p <> 't' 
and (upper(page_title) like upper('%$QQquery_string%')
     or upper(url_stub) like upper('%$QQquery_string%'))
order by $order_by_clause"]


while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    ns_write "<li><A HREF=\"page-summary.tcl?[export_url_vars page_id]\">$url_stub</a> ($page_title)\n"
}

ns_write "
</ul>

[ad_admin_footer]
"
