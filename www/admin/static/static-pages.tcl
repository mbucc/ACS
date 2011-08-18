# $Id: static-pages.tcl,v 3.0 2000/02/06 03:30:28 ron Exp $
set_the_usual_form_variables 0

# optional order_by, suppress_unindexed_p 

if { ![info exists order_by] || [empty_string_p $order_by] || $order_by == "url" } {
    set option "order by <a href=\"static-pages.tcl?order_by=title\">title</a>"
    set order_by_clause "url_stub, upper(rtrim(ltrim(page_title)))"
} elseif { $order_by == "title" } {
    set option "order by <a href=\"static-pages.tcl?order_by=url\">URL</a>"
    set order_by_clause "upper(rtrim(ltrim(page_title))), url_stub"
}

if { ![info exists suppress_unindexed_p] || !$suppress_unindexed_p } {
    set help_table [help_upper_right_menu [list "static-pages.tcl?suppress_unindexed_p=1&[export_url_vars order_by]" "suppress unindexed pages"]]
    set suppress_unindexed_p_clause ""
} else {
    # don't show pages that aren't indexed
    set help_table [help_upper_right_menu [list "static-pages.tcl?suppress_unindexed_p=0&[export_url_vars order_by]" "show unindexed pages"]]
    set suppress_unindexed_p_clause "\nand index_p <> 'f'"
}

ReturnHeaders

ns_write "[ad_admin_header "Static Pages"]

<h2>Static Pages</h2>

[ad_admin_context_bar [list "index.tcl" "Static Content"] "All Pages"]


<hr>

$help_table

$option

<ul>
"

set db [ns_db gethandle]

set selection [ns_db select $db "select page_id, rtrim(ltrim(page_title,' \n'),' \n') as page_title, url_stub
from static_pages
where draft_p <> 't' $suppress_unindexed_p_clause
order by $order_by_clause"]


while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    ns_write "<li><A HREF=\"page-summary.tcl?[export_url_vars page_id]\">$url_stub</a> ($page_title)\n"
}

ns_write "
</ul>

[ad_admin_footer]
"
