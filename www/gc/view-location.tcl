# $Id: view-location.tcl,v 3.1 2000/03/10 23:58:33 curtisg Exp $
set_form_variables
set_form_variables_string_trim_DoubleAposQQ

# domain_id, country, state

# Error Count and List
set exception_count 0
set exception_text ""

if {$state == "" && $country == ""} {
    incr exception_count
    append exception_text "<li> Please select a country or state."
}


if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}

set db [gc_db_gethandle]

if {$state != ""} {
    set state_name  " [ad_state_name_from_usps_abbrev $db $state]"
} else {
    set state_name ""
}


if {$country != ""} {
    set country_name  " [ad_country_name_from_country_code $db $country]"
} else {
    set country_name ""
}


append html "[gc_header "Ads in  $country_name $state_name"]

<h2>Ads in $country_name $state_name</h2>


<p>

<ul>
"

set selection [ns_db 1row $db [gc_query_for_domain_info $domain_id]]
set_variables_after_query


if { [info exists wtb_common_p] && $wtb_common_p == "t" } {
    set order_by "order by wanted_p, classified_ad_id desc"
} else {
    set order_by "order by classified_ad_id desc"
}

#  if an ad is listed as 'Iowa' and no county, it will still turn up
#  under a state for US and state Iowa (seach by state overrides)

set selection [ns_db select $db "select classified_ad_id,one_line, wanted_p
from classified_ads
where domain_id = $domain_id
and (state = '$state' or '$state' is null)
and (country = '$country' or '$country' is null or '$state' is not null) 
and (sysdate <= expires or expires is null)
$order_by"]

set counter 0
set wanted_p_yet_p 0

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    incr counter
    if { [info exists wtb_common_p] && $wtb_common_p == "t" && !$wanted_p_yet_p && $counter > 0 && $wanted_p == "t" } {
	# we've not seen a wanted_p ad before but this isn't the first
	# row, so write a headline
	append html "<h4>Wanted to Buy</h4>\n"
    }
    if { $wanted_p == "t" } {
	# we'll probably do this a bunch of times but that is OK
	set wanted_p_yet_p 1
    }
    append html "<li><a href=\"view-one.tcl?classified_ad_id=$classified_ad_id\">
$one_line
</a>
"

}

append html "</ul>

[gc_footer $maintainer_email]"

ns_return 200 text/html $html
