ad_page_contract {
    Reusable page to let an administrator pick a user group to associate with some other element in the database.

    @param target ultimate URL where we're heading with group_id set
    @param passthrough Tcl list of form variable names to pass along from caller
    @param explanation Reasoning behind the association

    @cvs-id pick.tcl,v 3.0.12.6 2000/09/22 01:36:16 kevin Exp
} {
    target:notnull
    {passthrough {[list]}}
    explanation:optional
}

set page_html "[ad_admin_header "Pick a User Group"]

<h2>Pick a User Group</h2>

<hr>

<ul>

"

if [info exists explanation] {
   append page_html "$explanation\n\n<p>\n"
}
 
if { ![info exists passthrough] } {
    set passthrough [list]
}

lappend passthrough "group_id"

set last_group_type_headline ""

db_foreach get_group_info "select ugt.pretty_plural as group_type_headline, ug.group_id, ug.group_type, ug.group_name
from user_groups ug, user_group_types ugt
where ug.group_type = ugt.group_type 
order by ug.group_type, upper(group_name)" {

    if { [string compare $last_group_type_headline $group_type_headline] != 0 } {
	append page_html "<h4>$group_type_headline</h4>\n\n"
	set last_group_type_headline $group_type_headline
    }
    append page_html "<li><a href=\"$target?[eval "export_url_vars $passthrough"]\">$group_name</a>\n"
}

append page_html "

</ul>

[ad_admin_footer]
"

doc_return  200 text/html $page_html
