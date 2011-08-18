# $Id: view-category.tcl,v 3.1.2.1 2000/04/28 15:10:33 carsten Exp $
#
# /gc/view-category.tcl
#
# by philg@mit.edu in 1995
#
# list ads within one category within one domain in the classifieds
#

set_the_usual_form_variables

# domain_id, primary_category

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



set db [gc_db_gethandle]
set selection [ns_db 1row $db [gc_query_for_domain_info $domain_id]]
set_variables_after_query

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

set selection [ns_db select $db "select classified_ad_id,one_line, wanted_p
from classified_ads
where domain_id = $domain_id
and primary_category = '$QQprimary_category'
and (sysdate <= expires or expires is null)
$order_by"]

set counter 0
set wanted_p_yet_p 0

set items ""

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
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
    append items "<li><a href=\"view-one.tcl?classified_ad_id=$classified_ad_id\">
$one_line
</a>
"

}

ns_db releasehandle $db

append whole_page $items

append whole_page "</ul>

[gc_footer $maintainer_email]"

ns_return 200 text/html $whole_page
