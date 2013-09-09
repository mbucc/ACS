# /www/admin/adserver/index.tcl

ad_page_contract {
    main adserver admin page
    @param none
    @author mchu@arsdigita.com
    @created 07/13/2000
    @cvs-id index.tcl,v 3.2.2.6 2000/11/20 23:55:18 ron Exp
}

set page_content "
[ad_admin_header "AdServer Administration"]

<h2>AdServer Administration</h2>

[ad_admin_context_bar "AdServer"]

<hr>

<p>Documentation for this subsystem is available at 
<a href=\"/doc/adserver\">/doc/adserver.html</a>.

<ul>
"


# Let's get the groups and their corresponding ads, the ads with no
# groups will arrive at the end

# first get any groups with no ads
set query_sql "
select group_key, 
       pretty_name 
from   adv_groups 
where  not group_key in (select group_key from adv_group_map)"

db_foreach adv_select_query $query_sql  {
    if ![empty_string_p $pretty_name] {
	set group_anchor $pretty_name
    } else {
	set group_anchor $group_key
    }
    append page_content "
    <li>Group 
    <a href=\"one-adv-group?[export_url_vars group_key]\">$group_anchor</a>\n"
}

set query_sql "
select map.group_key, 
       advs.adv_key
from   advs, 
       adv_group_map map
where  advs.adv_key = map.adv_key(+)
order  by upper(map.group_key), upper(advs.adv_key)"

set last_group_key ""
set doing_standalone_ads_now_p 0
set first_iteration_p 1

db_foreach adv_select_query $query_sql  {
    if { $first_iteration_p && [empty_string_p $group_key] } {
	# this installation doesn't use groups apparently
	set doing_standalone_ads_now_p 1
    }

    set first_iteration_p 0

    if { [string compare $group_key $last_group_key] != 0 } {
	if [empty_string_p $group_key] {
	    # we've come to the end of the grouped ads
	    set doing_standalone_ads_now_p 1
	    append page_content "<h4>ads that aren't in any group</h4>"
	} else {
	    set group_pretty_name [db_string adv_name_query "
	    select pretty_name from adv_groups where group_key = :group_key"]
	    if ![empty_string_p $group_pretty_name] {
		set group_anchor $group_pretty_name
	    } else {
		set group_anchor $group_key
	    }
	    append page_content "
	    <br>
	    <br>
	    <li>Group <a href=\"one-adv-group?[export_url_vars group_key]\">$group_anchor</a>"
	}
	set last_group_key $group_key
    }

    if $doing_standalone_ads_now_p {
	append page_content "
	<li><a href=\"one-adv?[export_url_vars adv_key]\">$adv_key</a>"
    } else {
	append page_content "<br><a href=\"one-adv?[export_url_vars adv_key]\">$adv_key</a>"
    }
}

db_release_unused_handles

append page_content "<p>

<li>Create a new <a href=\"add-adv\">ad</a> | <a href=\"add-adv-group\">ad group</a>

</ul>

[ad_admin_footer]
"

doc_return 200 text/html $page_content