# $Id: admin-authorize-group-new.tcl,v 3.0 2000/02/06 03:32:16 ron Exp $
set_form_variables

# topic

ReturnHeaders 

ns_write "[ad_admin_header "Authorize a group for $topic"]

<h2>Choose a group</h2>

to authorize for <a href=\"admin-authorized-users.tcl?[export_url_vars topic]\">$topic</a>

<hr>
"

set db [ns_db gethandle]

set selection [ns_db select $db "select ug.group_id, ug.group_name, ugt.pretty_plural
from user_groups ug, user_group_types ugt
where ug.group_type = ugt.group_type
and existence_public_p = 't'
and approved_p = 't'
order by upper(ug.group_type)"]

set last_pretty_plural ""
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    if { $last_pretty_plural != $pretty_plural } {
	ns_write "<h4>$pretty_plural</h4>\n"
	set last_pretty_plural $pretty_plural
    }
    ns_write "<li><a href=\"admin-authorize-group-new-2.tcl?[export_url_vars topic group_id]\">$group_name</a>\n"
}

ns_write "
</ul>
[bboard_footer]"
