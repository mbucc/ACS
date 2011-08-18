# $Id: archives.tcl,v 3.1 2000/03/11 09:03:12 aileen Exp $
# File:     /calendar/archives.tcl
# Date:     1998-11-18
# Contact:  philg@mit.edu, ahmeds@arsdigita.com
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

set_the_usual_form_variables 0
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)

ad_scope_error_check

set db [ns_db gethandle]
ad_scope_authorize $db $scope all group_member registered

set page_title "[ad_parameter SystemName calendar "Calendar"] Archives"

ReturnHeaders

ns_write "
[ad_scope_header $page_title $db]
[ad_scope_page_title $page_title $db]
from [ad_site_home_link]

<hr>
[ad_scope_navbar]

<ul>
"

set selection [ns_db select $db "select c.*
from calendar c , calendar_categories cc
where sysdate > c.expiration_date
and c.approved_p = 't'
and c.category_id=cc.category_id
and [ad_scope_sql cc]
order by c.start_date, c.creation_date"]

set counter 0
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    incr counter
    ns_write "<li><a href=\"item.tcl?[export_url_scope_vars calendar_id]\">$title</a>\n"
}

ns_write "</ul>

[ad_scope_footer]
"


