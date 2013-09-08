# /www/groups/index.tcl

ad_page_contract {
    display list of user groups
  
    @creation-date mid-1998
    @author teadams@arsdigita.com
    @author tarik@arsdigita.com
    @cvs-id index.tcl,v 3.3.2.7 2000/09/22 01:38:08 kevin Exp
} {
    groups_public_dir:notnull
    group_type_url_p:notnull
    group_public_root_url:notnull
    group_admin_root_url:notnull
    group_type:optional
    group_type_pretty_name:optional
    group_type_pretty_plural:optional
}

set user_id [ad_maybe_redirect_for_registration]

set document ""
if { ![info exists group_type_pretty_plural] } {
    set group_type_pretty_plural ""
}
set page_title [ad_decode $group_type_url_p 1 $group_type_pretty_plural "User Groups"]

append document "
[ad_header $page_title]
<h2>$page_title</h2>
[ad_context_bar_ws_or_index [ad_decode $group_type_url_p 1 $group_type_pretty_plural "Groups"]]
<hr>
"



set group_type_sql [ad_decode $group_type_url_p 1 "and ugt.group_type=:group_type" ""]

set sql "
select ug.short_name, ug.group_name, ugt.group_type as user_group_type, ugt.pretty_plural
from user_groups ug, user_group_types ugt
where ug.group_type = ugt.group_type
and approved_p = 't'
and (((new_member_policy = 'open' or new_member_policy = 'wait')
       and existence_public_p = 't')
     or exists (select 1 from user_group_map ugm
                where user_id = :user_id
                and   ugm.group_id = ug.group_id))
$group_type_sql
order by upper(ug.group_type), upper(ug.group_name)"

set html ""
set last_group_type ""
set group_counter 0
db_foreach groups_listing $sql {
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

append document "
<ul>
$html
</ul>

[ad_footer]
"


doc_return  200 text/html $document














