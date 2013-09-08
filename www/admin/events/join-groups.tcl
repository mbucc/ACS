ad_page_contract {
    Adds user to all user groups which own event activities.

    @param dummy parameter that prevents people from accidentally clicking on this page and joining a bunch of groups

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id join-groups.tcl,v 1.1.2.4 2000/09/22 01:35:07 kevin Exp
} {
    {proceed:notnull}
}

#we force this page to take a variable so that someone can't just
#load the page and accidentally join all the user groups

set user_id [ad_verify_and_get_user_id]

append whole_page "
[ad_header "Joined Groups"]
<h2>Joined Groups</h2>
[ad_admin_context_bar [list "index" "Events"] "Join Groups"]
<hr>
You were added as an administrator to the following groups:
<ul>
"

db_transaction {

    set groups_html ""
    
    set ip_address [ns_conn peeraddr]
    
    db_foreach evnt_sel_groups_to_join {
	select
	distinct ug.group_id, ug.group_name, ug.group_type
	from user_groups ug, events_activities a
	where ug.group_id = a.group_id
	and ug.group_id not in
	(select group_id
	 from user_group_map
	 where user_id = :user_id)
    } {
	db_dml evnt_join_ug {
	    insert into user_group_map
	    (group_id, user_id, role, mapping_user, mapping_ip_address)
	    values
	    (:group_id, :user_id, 'administrator', :user_id, :ip_address)
	}
	append groups_html "<li><a href=\"/admin/ug/group?[export_url_vars group_id]\">$group_name</a> ($group_type group type)"
    }
} 

if {[empty_string_p $groups_html]} {
	append whole_page "<li>You were not added to any groups.  You 
    probably already belonged to them all."
} else {
    append whole_page $groups_html
}

append whole_page "
</ul>

[ad_footer]
"


doc_return  200 text/html $whole_page

