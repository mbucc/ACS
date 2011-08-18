# $Id: adserver-defs.tcl,v 3.0 2000/02/06 03:12:57 ron Exp $
# definitions for the ad server; adserver_get_ad_html is called by
# .tcl, .adp, or .html pages (by filters, presumably)
# to generate ad IMGs (linked to HREFs)

proc adserver_get_ad_html {group_key {extra_img_tags ""}} {
    set adserver_stub [ad_parameter PartialUrlStub adserver] 
    set db [ns_db gethandle subquery ]
    
    # right now, all we can really do is pick the ad in the specified
    # group with the least exposure so far
    set selection [ns_db select $db "select map.adv_key, track_clickthru_p, target_url
from adv_group_map map, advs_todays_log log, advs
where group_key='$group_key'
and map.adv_key = advs.adv_key
and map.adv_key = log.adv_key(+)
order by nvl(display_count,0)"]
    # we only want the first row
    if [ns_db getrow $db $selection] {
	# we got one row
	set_variables_after_query
	# normally we generate the images through a call to adimg.tcl wrapped in an adhref.tcl 
	# href.  If track_clickthru_p is false, just spew out the html contained in target_url
	# forget about it.  This is how we deal with doubleclick and their ilk.
	if {$track_clickthru_p == "t"} {
	    return "<a href=\"${adserver_stub}adhref.tcl?adv_key=$adv_key\"><img src=\"${adserver_stub}adimg.tcl?adv_key=$adv_key\" $extra_img_tags></a>"
	} else {
	    # update the impressions since this won't get called through adimg.tcl

	    ns_db dml $db "update adv_log 
set display_count = display_count + 1 
where adv_key='$adv_key'
and entry_date = trunc(sysdate)"

	    set n_rows [ns_ora resultrows $db]

	    if { $n_rows == 0 } {
		ns_db dml $db "insert into adv_log 
(adv_key, entry_date, display_count) 
values 
('$adv_key', trunc(sysdate), 1)"
            }

            regsub -all {\$timestamp} $target_url [ns_time] cache_safe_target
	    ns_db releasehandle $db	
	    return $cache_safe_target
	}
    } else {
	# couldn't even find one row
	ns_log Notice "[ns_conn url] asked for an ad in the $group_key group but there aren't any"
	ns_db releasehandle $db	
	return ""
    }
}

