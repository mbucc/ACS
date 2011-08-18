# $Id: index.tcl,v 3.0 2000/02/06 03:36:09 ron Exp $
# File:     /calendar/admin/index.tcl
# Date:     1998-11-18
# Contact:  philg@mit.edu, ahmeds@arsdigita.com
# Purpose:  calendar main page
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

set_the_usual_form_variables 0
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)

ad_scope_error_check
set db [ns_db gethandle]
ad_scope_authorize $db $scope admin group_admin none


ReturnHeaders

ns_write "
[ad_scope_admin_header "Calendar Administration" $db]
[ad_scope_admin_page_title "Calendar Administration" $db]
[ad_scope_admin_context_bar "Calendar"]

<hr>

<ul>
"

set selection [ns_db select $db "
select c.*, expired_p(c.expiration_date) as expired_p
from calendar c , calendar_categories cc
where c.category_id=cc.category_id
and [ad_scope_sql cc]
order by expired_p, c.creation_date desc"]

set counter 0 
set expired_p_headline_written_p 0
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    incr counter 
    if { $expired_p == "t" && !$expired_p_headline_written_p } {
	ns_write "<h4>Expired Calendar Items</h4>\n"
	set expired_p_headline_written_p 1
    }
    ns_write "<li>[util_AnsiDatetoPrettyDate $start_date] - [util_AnsiDatetoPrettyDate $end_date]: <a href=\"item.tcl?[export_url_scope_vars calendar_id]\">$title</a>"
    if { $approved_p == "f" } {
	ns_write "&nbsp; <font color=red>not approved</font>"
    }
    ns_write "\n"
}

ns_write "

<P>

<li><a href=\"post-new.tcl?[export_url_scope_vars]\">add an item</a>

<p>

<li><a href=\"categories.tcl?[export_url_scope_vars]\">categories</a>

</ul>

[ad_scope_admin_footer]
"

