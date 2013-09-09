# /groups/admin/index.tcl

ad_page_contract {
    @cvs-id index.tcl,v 3.2.6.6 2000/09/22 01:38:09 kevin Exp
 Purpose: display list of user groups for which user has group administration privileges
 
 Note: groups_public_dir, group_type_url_p, group_type, group_type_pretty_name, 
       group_type_pretty_plural, group_public_root_url and group_admin_root_url
       are set in this environment by ug_serve_group_pages. if group_type_url_p
       is 0, then group_type, group_type_pretty_name and group_type_pretty_plural
       are empty strings
} {
    group_type_url_p:notnull
    group_public_root_url:notnull
    group_admin_root_url:notnull
    group_type:optional
    group_type_pretty_plural:optional
    group_type_pretty_name:optional
}

if { ![info exists group_type_pretty_name] } {
    set group_type_pretty_name ""
}
set user_id [ad_get_user_id]

if {$user_id == 0} {
    ad_returnredirect "/register.tcl?return_url=[ad_urlencode "[ug_admin_url]/"]"
    return
}

set page_html ""

set page_title [ad_decode $group_type_url_p 1 "$group_type_pretty_name Administration" "Group Administration"]

append page_html "
[ad_header $page_title]
<h2>$page_title</h2>
[ad_admin_context_bar $page_title]
<hr>
"



set group_type_sql [ad_decode $group_type_url_p 1 "and ugt.group_type=:group_type" ""]
set last_group_type ""
set group_counter 0
db_foreach get_ug_info "
select ug.short_name, ug.group_name, ugt.group_type, ugt.pretty_plural
from user_groups ug, user_group_types ugt, users u
where u.user_id=:user_id
and ad_user_has_role_p ( :user_id, ug.group_id, 'administrator' ) = 't'
and ug.approved_p = 't'
$group_type_sql
and ugt.group_type= ug.group_type
order by upper(ug.group_type)" {
    if { $last_group_type != $group_type && !$group_type_url_p } {
	append group_html "<h4>$pretty_plural</h4>\n"
	set last_group_type $group_type
    }
    append group_html "<li><a href=\"$group_admin_root_url/[ad_urlencode $short_name]/\">$group_name</a>\n"
    incr group_counter
}

if { $group_counter > 0 } {
    append html $group_html
} else {
    append html "
    You do not have administrator privileges for any of the
    groups at <a href=/>[ad_system_name]</a>
    <br>
    You can browse through existing groups at <a href=[ug_url]/>[ad_parameter SystemURL][ug_url]</a>
    <br>"
}

append page_html "
<ul>
$html
</ul>

[ad_footer]
"

doc_return  200 text/html $page_html
