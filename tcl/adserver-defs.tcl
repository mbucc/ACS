# /tcl/adserver-defs.tcl

ad_library {
    definitions for the ad server; adserver_get_ad_html is called by
    .tcl, .adp, or .html pages (by filters, presumably) to generate ad
    IMGs (linked to HREFs).    An API for managing database queries.

    @author mchu@arsdigita.com
    @created modified 07/13/2000
    @cvs-id adserver-defs.tcl,v 3.2.6.4 2000/11/20 23:55:13 ron Exp
}

ad_proc adserver_get_random_ad_key {group_key} {
    Returns random adv key 
} {
    set ad_list [db_list_of_lists ad_list_query "
    select map.adv_key
    from   adv_group_map map, advs
    where  group_key   = :group_key
    and    map.adv_key = advs.adv_key"]

    set n_available  [llength $ad_list]
    set random_index [randomRange $n_available]
    return [lindex $ad_list $random_index]
    
}

ad_proc adserver_get_sequential_ad_key {group_key} {
    Returns sequential adv_key
} {

    set user_id [ad_get_user_id]

    set selection [db_0or1row adserver_adv_key {
	select nvl(rotation_order,0)+1 as rotation_order,
	       (select max(rotation_order)
                from   adv_group_map
                where  group_key=:group_key) as max_rotation_order
      	from   adv_group_map grp,
	       adv_user_map map
	where  user_id     = :user_id
	and    event_time  = (select max(event_time) from adv_user_map map)
        and    group_key   = :group_key
        and    grp.adv_key = map.adv_key
        and    map.user_id = :user_id}]

	if {!$selection} {
	    set rotation_order 1
	} else {
	    if {$rotation_order > $max_rotation_order} {
		set rotation_order 1
	    }
	}

     return [db_string adserver_adv_key {
	 select adv_key 
         from   adv_group_map
         where  group_key      = :group_key
         and    rotation_order = :rotation_order} -default ""]

}

ad_proc adserver_get_least_exposure_ad_key {group_key} {
    Return adv_key for the ad with the last exposure
} {
    set adv_key ""

    db_foreach get_ad_key {
	select map.adv_key
	from   adv_group_map map, 
	       advs_todays_log log, 
	       advs
	where  group_key   = :group_key
	and    map.adv_key = advs.adv_key
	and    map.adv_key = log.adv_key(+)
	order  by nvl(display_count,0)
    } {
	# stop on the first pass though this loop and return the first
	# add selected 

	break
    }

    return $adv_key
}


ad_proc adserver_get_ad_html {
    group_key 
    {extra_img_tags ""}
} {
    right now, all we can really do is pick the ad in the specified
    group with the least exposure so far
} {

    set rotation_method [db_string ad_rotation_method "
    select rotation_method 
    from   adv_groups
    where  group_key = :group_key" -default ""]

    set rotation_method [string trim $rotation_method]

    switch $rotation_method {

	least-exposure-first {

	    set adv_key [adserver_get_least_exposure_ad_key $group_key]
	    set sql_query "
	    select track_clickthru_p,
	           target_url
	    from   advs
	    where  adv_key=:adv_key"
	} 

	random {
	    set adv_key [adserver_get_random_ad_key $group_key]
	    set sql_query "
	    select track_clickthru_p,
	           target_url
	    from   advs
	    where  adv_key=:adv_key"
	} 

	sequential {
	    set adv_key [adserver_get_sequential_ad_key $group_key]
	    set sql_query "
	    select track_clickthru_p,
	           target_url
	    from   advs
	    where  adv_key=:adv_key"
	}
    }

    if [db_0or1row ad_server_defs_adv_select_first_row_query $sql_query] {
	# we got one row
	
	# normally we generate the images through a call to adimg.tcl
	# wrapped in an adhref.tcl href.  If track_clickthru_p is
	# false, just spew out the html contained in target_url and forget
	# about it.  This is how we deal with doubleclick and their
	# ilk. 

	set adserver_stub [ad_parameter PartialUrlStub adserver] 
	set adserver_img  "<img src=\"${adserver_stub}adimg?adv_key=$adv_key\" $extra_img_tags>"

	if {$track_clickthru_p == "t"} {
	    set result "
	    <a href=\"${adserver_stub}adhref?adv_key=$adv_key\">$adserver_img</a>"
	} else {
	    # update the impressions since this won't get called through adimg.tcl
	    db_dml adserver_defs_adv_update "
	    update adv_log 
	    set    display_count = display_count + 1 
	    where  adv_key       = :adv_key 
	    and    entry_date    = trunc(sysdate)"
	    
	    set n_rows [db_resultrows]
	    
	    if { $n_rows == 0 } {
		db_dml adv_insert "
		insert into adv_log 
		(adv_key, entry_date, display_count) 
		values 
		(:adv_key, trunc (sysdate), 1)"
	    }
	    
	    regsub -all {\$timestamp} $target_url [ns_time] cache_safe_target
	    set result "<a href=\"$cache_safe_target\">$adserver_img</a>"

	    set user_id [ad_get_user_id]
	    
	    if {$user_id != 0} {
 		db_dml adserver_defs_adv_user_insert {
		    insert into adv_user_map 
		    (user_id, adv_key, event_time, event_type)
		    values 
		    (:user_id, :adv_key, sysdate, 'd')
		}
	    }
	}
    } else {
	# couldn't even find one row
	ns_log Notice "[ns_conn url] asked for an ad ($adv_key) in the $group_key group but there aren't any: \n $sql_query"
	set result ""
    }
    
    db_release_unused_handles
    return $result
}
	











