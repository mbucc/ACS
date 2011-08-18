# $Id: domain-all.tcl,v 3.1 2000/03/10 23:58:23 curtisg Exp $
set_the_usual_form_variables

# domain_id, by_category_p, wtb_p

set db [gc_db_gethandle]

set selection [ns_db 1row $db [gc_query_for_domain_info $domain_id]]
set_variables_after_query


append html "[gc_header "$full_noun Ads"]

<h2>All Ads</h2>

[ad_context_bar_ws_or_index [list "index.tcl" [gc_system_name]] [list "domain-top.tcl?[export_url_vars domain_id]" $full_noun] "All Ads"]

<hr>

<ul>
"

set list_items ""

if { $by_category_p == "t" } {
    set order_by "order by primary_category"
} else {
    set order_by "order by classified_ad_id desc"
}

if { [info exists wtb_p] && $wtb_p == "f" } {
   set wtb_restriction "and wanted_p = 'f'"
} else {
   set wtb_restriction ""
}

set selection [ns_db select $db "select classified_ad_id,one_line,primary_category as category
from classified_ads
where domain_id = $domain_id $wtb_restriction
and (sysdate <= expires or expires is null)
$order_by"]

set last_category_printed ""
set first_loop_flag 1

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    if { $category != $last_category_printed && $by_category_p == "t" } {
	append list_items "</ul><h3>$category</h3>\n<ul>"
	set last_category_printed $category
    }
    append list_items "<li><a href=\"view-one.tcl?classified_ad_id=$classified_ad_id\">
$one_line</a>
"
    set first_loop_flag 0
}

if { $first_loop_flag  == 1 } {
    # we never even got one row
    append list_items "there aren't any unexpired ads in this domain"
}

ns_db releasehandle $db

append html "$list_items

</ul>

[gc_footer $maintainer_email]"

ns_return 200 text/html $html
