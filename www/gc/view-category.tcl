# /gc/view-category.tcl

ad_page_contract {
    list ads within one category within one domain in the classifieds

    @author philg@mit.edu 
    @creation-date 1995
    @cvs-id view-category.tcl,v 3.4.2.5 2000/09/22 01:37:57 kevin Exp
} {
    domain_id:integer
    primary_category
}

if { ![info exists domain_id] || [empty_string_p $domain_id] } {
    # we don't know which domain this is
    ad_returnredirect "/gc/"
    return
}

if { ![info exists primary_category] || [empty_string_p $primary_category] } {
    # we don't know which category this is
    ad_returnredirect "domain-top.tcl?[export_url_vars domain_id]"
    return
}

set whole_page ""

append whole_page "[gc_header "$primary_category Ads"]

<h2>$primary_category Ads</h2>"


db_1row gc_view_cat_get_domain_info [gc_query_for_domain_info $domain_id]


append whole_page "
[ad_context_bar_ws_or_index [list "index.tcl" [gc_system_name]] [list "domain-top.tcl?[export_url_vars domain_id]" $full_noun] "One Category"]

<hr>

<ul>
"

if { [info exists wtb_common_p] && $wtb_common_p == "t" } {
    set order_by "order by wanted_p, classified_ad_id desc"
} else {
    set order_by "order by classified_ad_id desc"
}

set sql "
    select classified_ad_id, one_line, wanted_p
    from classified_ads
    where domain_id = :domain_id
    and primary_category = :primary_category
    and (sysdate <= expires or expires is null)
    $order_by"

set counter 0
set wanted_p_yet_p 0

set items ""

db_foreach gc_view_category_ad_list $sql {    
    incr counter
    if { [info exists wtb_common_p] && $wtb_common_p == "t" && !$wanted_p_yet_p && $counter > 0 && $wanted_p == "t" } {
	# we've not seen a wanted_p ad before but this isn't the first
	# row, so write a headline
	append items "<h4>Wanted to Buy</h4>\n"
    }
    if { $wanted_p == "t" } {
	# we'll probably do this a bunch of times but that is OK
	set wanted_p_yet_p 1
    }
    append items "<li><a href=\"view-one?classified_ad_id=$classified_ad_id\">
$one_line
</a>
"

}

append whole_page "
$items

</ul>

[gc_footer $maintainer_email]"

doc_return  200 text/html $whole_page

