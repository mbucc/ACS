# $Id: pick.tcl,v 3.0 2000/02/06 03:29:46 ron Exp $
# reusable page to let an administrator pick a user group to associate
# with some other element in the database

set_the_usual_form_variables

# target (ultimate URL where we're heading with group_id set)
# passthrough (Tcl list of form variable names to pass along from caller)
# maybe explanation

ReturnHeaders

ns_write "[ad_admin_header "Pick a User Group"]

<h2>Pick a User Group</h2>

<hr>

<ul>

"

if [info exists explanation] {
   ns_write "$explanation\n\n<p>\n"
}

set db [ns_db gethandle] 

set selection [ns_db select $db "select ugt.pretty_plural as group_type_headline, ug.group_id, ug.group_type, ug.group_name
from user_groups ug, user_group_types ugt
where ug.group_type = ugt.group_type 
order by ug.group_type, upper(group_name)"]

if { ![info exists passthrough] } {
    set passthrough [list]
}
lappend passthrough "group_id"

set last_group_type_headline ""
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    if { [string compare $last_group_type_headline $group_type_headline] != 0 } {
	ns_write "<h4>$group_type_headline</h4>\n\n"
	set last_group_type_headline $group_type_headline
    }
    ns_write "<li><a href=\"$target?[eval "export_url_vars $passthrough"]\">$group_name</a>\n"
}

ns_write "

</ul>

[ad_admin_footer]
"
