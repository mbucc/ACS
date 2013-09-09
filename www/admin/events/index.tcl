ad_page_contract {
    This is the Site-Wide Events Administration Page.

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id index.tcl,v 1.5.2.3 2000/09/22 01:35:07 kevin Exp
} {
}

set events_admin_group_id [db_string evnt_sel_admin_group "select
group_id
from user_groups
where group_name = 'Events Administration'
and group_type = 'administration'
and short_name = 'events'"]

append whole_page "[ad_header "Events Administration"]
<h2>Events Administration</h2>
[ad_admin_context_bar "Events"]
<hr>

<h3>Administrate Events</h3>

<ul>
<li>To administrate an event, go to
<a href=\"/events/admin/\">/events/admin/</a>
<li>To become an events administrator, go to
<a href=\"/admin/ug/member-add?group_id=$events_admin_group_id\">/admin/ug/member-add?group_id=$events_admin_group_id</a>
and add yourself to the events administration user group
</ul>

<h3>Join a User Group</h3>

If you wish to administrate an event, you must belong to that event's
activity's owning user group.  Following is a list of user groups
which currently own activities.  You may add yourself (or another
person) as a member/administrator to any of these groups so that you
can administrate that group's activities.

<ul>
"

set first_group_p 1
set last_group_id ""

db_foreach evnt_sel_evnt_groups "select
distinct ug.group_id, ug.group_name, ug.group_type, a.short_name
from user_groups ug, events_activities a
where ug.group_id = a.group_id
order by upper(group_name), upper(short_name)
" {
    if {($last_group_id != $group_id) || ($first_group_p == 1)} {
	if {$first_group_p != 1} {
	    append whole_page "</ul>"
	}
	    
	append whole_page "
	<li><a href=\"/admin/ug/member-add?group_id=$group_id\">
	$group_name</a> ($group_type group type)
	<ul>
	"
	set first_group_p 0
	set last_group_id $group_id
    }

    append whole_page "<li>$short_name"
}

append whole_page "</ul>"

set header "Join All Activity User Groups"
set message "Are you sure you want to join all the user groups
that own activities?"
set yes_url "/admin/events/join-groups?proceed=1"
set no_url "/admin/events/"

append whole_page "
<p>
<li><a href=\"/shared/confirm?[export_url_vars header message yes_url no_url]\">Join all the above user groups</a>
</ul>"

append whole_page "[ad_footer]
"



doc_return  200 text/html $whole_page