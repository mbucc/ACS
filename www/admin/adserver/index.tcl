# $Id: index.tcl,v 3.0 2000/02/06 02:46:09 ron Exp $
ReturnHeaders 

ns_write "[ad_admin_header "AdServer Administration"]

<h2>AdServer Administration</h2>

[ad_admin_context_bar "AdServer"]


<hr>

<ul>

"

# Let's get the groups and their corresponding ads, the ads with no
# groups will arrive at the end

set db_conns [ns_db gethandle [philg_server_default_pool] 2]
set db [lindex $db_conns 0]
set db_sub [lindex $db_conns 1]

# first get any groups with no ads
set selection [ns_db select $db "select group_key, pretty_name from adv_groups where not group_key in (select group_key from adv_group_map)"]
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    if ![empty_string_p $pretty_name] {
	set group_anchor $pretty_name
    } else {
	set group_anchor $group_key
    }
    ns_write "<li>Group <a href=\"one-adv-group.tcl?[export_url_vars group_key]\">$group_anchor</a>\n"
}

set selection [ns_db select $db "select map.group_key, advs.adv_key
from advs, adv_group_map map
where advs.adv_key = map.adv_key(+)
order by upper(map.group_key), upper(advs.adv_key)"]

set last_group_key ""
set doing_standalone_ads_now_p 0
set first_iteration_p 1
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    if { $first_iteration_p && [empty_string_p $group_key] } {
	# this installation doesn't use groups apparently
	set doing_standalone_ads_now_p 1
    }
    set first_iteration_p 0
    if { [string compare $group_key $last_group_key] != 0 } {
	if [empty_string_p $group_key] {
	    # we've come to the end of the grouped ads
	    set doing_standalone_ads_now_p 1
	    ns_write "<h4>ads that aren't in any group</h4>"
	} else {
	    set group_pretty_name [database_to_tcl_string $db_sub "select pretty_name from adv_groups where group_key = '[DoubleApos $group_key]'"]
	    if ![empty_string_p $group_pretty_name] {
		set group_anchor $group_pretty_name
	    } else {
		set group_anchor $group_key
	    }
	    ns_write "<li>Group <a href=\"one-adv-group.tcl?[export_url_vars group_key]\">$group_anchor</a>:\n"
	}
	set last_group_key $group_key
    }
    if $doing_standalone_ads_now_p {
	ns_write "<li>"
    }
    ns_write "<a href=\"one-adv.tcl?[export_url_vars adv_key]\">$adv_key</a> "
}

ns_write "<p>

<li>Create a new <a href=\"add-adv.tcl\">ad</a> | <a href=\"add-adv-group.tcl\">ad group</a>

</ul>

Documentation for this subsystem is available at 
<a href=\"/doc/adserver.html\">/doc/adserver.html</a>.

[ad_admin_footer]
"
