# /www/gc/domain-all.tcl

ad_page_contract {
    @cvs-id domain-all.tcl,v 3.3.2.5 2000/09/22 01:37:52 kevin Exp
} {
    domain_id:integer
    by_category_p
    wtb_p
}

db_1row domain_info_get [gc_query_for_domain_info $domain_id]

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

set sql "select classified_ad_id,one_line,primary_category as category
         from classified_ads
         where domain_id = :domain_id 
         $wtb_restriction
         and (sysdate <= expires or expires is null)
         $order_by"

set last_category_printed ""
set first_loop_flag 1

db_foreach domain_all_ads_list $sql -bind [ad_tcl_vars_to_ns_set domain_id] {
    if { $category != $last_category_printed && $by_category_p == "t" } {
	append list_items "</ul><h3>$category</h3>\n<ul>"
	set last_category_printed $category
    }
    append list_items "<li><a href=\"view-one?classified_ad_id=$classified_ad_id\">
$one_line</a>
"
    set first_loop_flag 0
}

if { $first_loop_flag  == 1 } {
    # we never even got one row
    append list_items "there aren't any unexpired ads in this domain"
}

db_release_unused_handles

append html "$list_items

</ul>

[gc_footer $maintainer_email]"

doc_return  200 text/html $html
