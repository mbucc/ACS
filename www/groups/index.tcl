# $Id: index.tcl,v 3.1 2000/02/10 03:19:04 ron Exp $
# File: /groups/index.tcl
# Date: mid-1998
# Contact: teadams@arsdigita.com, tarik@arsdigita.com
# Purpose: display list of user groups
# 
# Note: groups_public_dir, group_type_url_p, group_type, group_type_pretty_name, 
#       group_type_pretty_plural, group_public_root_url and group_admin_root_url
#       are set in this environment by ug_serve_group_pages. if group_type_url_p
#       is 0, then group_type, group_type_pretty_name and group_type_pretty_plural
#       are empty strings)


ReturnHeaders 

set page_title [ad_decode $group_type_url_p 1 $group_type_pretty_plural "User Groups"]

ns_write "
[ad_header $page_title]
<h2>$page_title</h2>
[ad_context_bar_ws_or_index [ad_decode $group_type_url_p 1 $group_type_pretty_plural "Groups"]]
<hr>
"

set db [ns_db gethandle]

set group_type_sql [ad_decode $group_type_url_p 1 "and ugt.group_type='[DoubleApos $group_type]'" ""]

set selection [ns_db select $db "
select ug.short_name, ug.group_name, ugt.group_type as user_group_type, ugt.pretty_plural
from user_groups ug, user_group_types ugt
where ug.group_type = ugt.group_type
and existence_public_p = 't'
and approved_p = 't'
$group_type_sql
order by upper(ug.group_type)"]

set html ""
set last_group_type ""
set group_counter 0
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    if { $last_group_type != $user_group_type && !$group_type_url_p } {
	append group_html "<h4>$pretty_plural</h4>\n"
	set last_group_type $user_group_type
    }
    append group_html "<li><a href=\"$group_public_root_url/[ad_urlencode $short_name]/\">$group_name</a>\n"
    incr group_counter
}

if { $group_counter > 0 } {
    append html $group_html
} else {
    append html "There are no publicly accessible groups in the database right now. "
}


ns_write "
<ul>
$html
</ul>

[ad_footer]
"
